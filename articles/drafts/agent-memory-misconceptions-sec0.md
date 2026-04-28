# 记忆幻象：Agent 框架的「记忆」承诺与工程现实

## §0 摘要（~1,000 字）

2023 到 2026 年，「记忆」成为开源 Agent 框架中最泛滥的词汇之一。几乎每个框架的 README 都包含这个词，但很少有人追问：这些框架说的「记忆」，是同一回事吗？

答案是否定的。Mem0 把记忆定义为「通用记忆层」，核心是一个 3,222 行的 `Memory` 类，采用 ADD-only 提取策略和多信号检索 [ref: facts/mem0-001.md]。Letta（原 MemGPT）把记忆定义为「上下文窗口中的保留区」，核心是一个带标签的 `Block` 抽象，Agent 通过显式工具调用直接编辑自己的记忆 [ref: facts/letta-001.md]。LangGraph 把记忆拆成「short-term memory」（单 session 的 state channels）和「long-term memory」（跨 session 的 checkpoint 持久化），但 checkpoint 的设计目标是「durable execution」——失败后从快照恢复，不是 Agent 的跨 session 学习 [ref: facts/langgraph-001.md]。CrewAI 同时提供 memory、 knowledge 和 rag 三个子系统，底层都依赖向量存储和 embedding，API 边界模糊到用户分不清该用哪个 [ref: facts/crewai-001.md]。AutoGen 在 Extensions API 中列出 ListMemory、RedisMemory、Mem0、ChromaDB 四种后端，但没有统一记忆抽象 [ref: facts/autogen-001.md]。OpenHands 的 State 对象保存「事件历史」和「长期计划」，通过 EventStream 持久化——这是执行轨迹的存储，不是结构化记忆 [ref: facts/openhands-001.md]。smolagents 则干脆不提供内置持久化记忆，把问题完全留给用户 [ref: facts/smolagents-001.md]。

七个框架，七种互不兼容的「记忆」实现。这不是术语偏好差异，而是根本架构假设的分歧：记忆应该存在向量数据库里还是上下文窗口里？应该由 LLM 自动提取还是由 Agent 显式编辑？应该累积不变还是允许覆盖删除？是执行状态的快照还是学习到的信念？

中文技术社区对 Agent 记忆的讨论集中在两个极端：一端是把「记忆」简化为「把历史对话存入向量数据库」的入门教程，另一端是独立基础设施项目（Mem0、Letta）的宣传材料。中间地带——框架内置记忆方案的语义混乱、概念重叠和工程陷阱——几乎无人系统梳理。本文填补这个缺口。

全文围绕三个反直觉发现展开。

**第一，上下文窗口的扩容不能解决记忆问题，因为记忆的核心挑战不是「能装多少」，而是「什么该保留、如何组织、如何更新」。** Mem0 在 2026 年 4 月发布的 benchmark 显示，专用记忆层在 LoCoMo 长程对话评估中得分 91.6，LongMemEval 得分 93.4 [ref: facts/mem0-001.md]。这些数字说明，即使在 1M token 上下文中，没有结构化记忆管理的系统 recall 得分显著低于专用记忆层。记忆是结构设计问题，不是容量问题。

**第二，RAG 与记忆的本质差异不在实现方式，而在语义目标。** RAG 的目标是「检索相关文档」，记忆的目标是「维护一个关于用户、世界和自我的可更新信念系统」。CrewAI 将 memory、knowledge、rag 分成三个子系统，但这三个子系统底层都依赖 ChromaDB/LanceDB 向量存储和 embedding 检索 [ref: facts/crewai-001.md]。这种分层在 API 文档中看起来清晰，在源码中却高度重叠——一个从 PDF 加载的 knowledge 条目和一个从对话中提取的 memory 条目，在向量数据库里是同一类记录。用户被三个名词误导，以为自己在做三种不同的事。

**第三，框架的「长期记忆」承诺与 checkpoint 的实现之间存在语义鸿沟。** LangGraph 的 checkpoint 是「执行恢复」机制——当流程失败时从快照重启 [ref: facts/langgraph-001.md]。这与人类直觉中的「长期记忆」（跨 session 积累知识、调整行为）不是一回事。把 checkpoint 称为 long-term memory，是用一个已有认知框架的概念去包装一个完全不同的技术机制，掩盖了「执行状态」与「学习到的知识」之间的本质区别。

对于需要在 2026 年设计或评估 Agent 记忆系统的工程师，本文提供的不是功能清单式的对比表，而是一套识别「记忆幻象」的分析框架——当一个框架声称自己「支持记忆」时，它的实现究竟在哪个语义层级上运作，以及这种层级选择对工程决策的隐性约束。
