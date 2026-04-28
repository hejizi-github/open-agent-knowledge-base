# 记忆幻象：Agent 框架的「记忆」承诺与工程现实

## §5 独立记忆层的崛起：Mem0 与 Letta 的两条道路（~2,000 字）

### §5.1 当框架内置记忆不够时

§2 到 §4 的分析揭示了一个共同的结论：主流 Agent 框架内置的「记忆」方案，在语义上都不够「记忆」。上下文窗口解决的是容量问题，不是组织结构问题；RAG 解决的是文档检索问题，不是信念维护问题；checkpoint 解决的是执行恢复问题，不是知识学习问题。

当工程团队的需求超越「在当前 session 中记住几句对话」时，框架内置方案的天花板变得清晰可见。这时，两条独立演进的道路出现在面前：**把记忆做成外部可插拔的基础设施层**（Mem0 的道路），或者**把记忆做成 Agent 的核心架构抽象**（Letta 的道路）。

这不是「用哪个库更好」的技术选型问题，而是「记忆在 Agent 系统中扮演什么角色」的架构假设问题。Mem0 和 Letta 的答案截然不同，而理解这种差异是做出正确工程决策的前提。

### §5.2 Mem0：记忆作为外部独立层

Mem0 的自我定位非常明确："Universal memory layer for AI Agents" [ref: facts/mem0-001.md]。它不是某个框架的插件，而是一个独立的记忆服务，通过 API 与任何 Agent 集成。

这种定位决定了它的架构选择。**记忆存储在向量数据库中**，与 Agent 的运行时解耦。Mem0 支持 15 种以上的向量存储后端——从 Qdrant、pgvector 到 Pinecone、RedisVL——开发者可以选择已有的基础设施，无需为记忆单独部署存储 [ref: facts/mem0-001.md]。

Mem0 的核心创新是**多信号检索系统**。它的 `search()` 方法同时运行三路检索：语义相似度搜索捕获同义词关联，BM25 关键词匹配捕获精确术语，实体关联提升确保同一实体的多条记忆被同时召回 [ref: facts/mem0-001.md]。三路结果分别打分后融合，而非简单的串联或取交集。这种设计的工程直觉是：记忆检索不是「找最相似的向量」，而是「用多种方式确认某条记忆与当前查询相关」。

在记忆更新策略上，Mem0 选择了激进的 **ADD-only 单通道提取**。`add()` 方法的 7 阶段流水线中，LLM 从对话中自动提取结构化记忆片段，MD5 hash 去重后存入向量存储 [ref: facts/mem0-001.md]。旧记忆不会被覆盖——如果用户改变了看法，新版本作为新记录插入，旧版本保留在 SQLite 的 `history` 表中。这种设计的代价是存储膨胀，但收益是完整的审计追踪和冲突信息的显式保留。

Mem0 还将记忆分为 **User、Session、Agent 三个层级** [ref: facts/mem0-001.md]。User 层级存储跨会话的持久事实（如用户的饮食偏好），Session 层级存储当前对话的短期上下文，Agent 层级存储 Agent 自身的策略性记忆。这种分层让检索有明确的搜索空间——查询用户偏好时不必遍历所有会话的历史消息。

Mem0 的适用场景可以概括为：**为已有 Agent 系统添加记忆能力**。无论 Agent 是用 LangGraph、CrewAI 还是自建框架实现的，只要调用 Mem0 的 API，就能获得跨 session 的持久记忆。截至 2026 年 4 月，Mem0 拥有 54,291 个 star，是独立记忆层项目中社区规模最大的 [ref: facts/mem0-001.md]。

### §5.3 Letta：记忆作为核心架构抽象

Letta（原 MemGPT）走了另一条路。它的仓库描述不是 "memory layer"，而是 "platform for building stateful agents with advanced memory" [ref: facts/letta-001.md]。记忆不是附加组件，而是构建 Agent 的**核心架构抽象**。

Letta 的核心设计是 **Block**——"A Block represents a reserved section of the LLM's context window" [ref: facts/letta-001.md]。每个 Agent 默认携带两个 Block：`Human`（存储关于用户的信息）和 `Persona`（存储 Agent 的自我角色定义）。Block 有标签、有字符上限、有读写权限控制——它是一个**带语义类型的结构化保留区**，不是无差别的文本块。

这与 Mem0 的架构形成根本对比。Mem0 的记忆存储在外部数据库，检索后注入系统 prompt；Letta 的记忆**本身就是上下文窗口的一部分**，Agent 在每次推理时直接「看到」自己的记忆，无需检索步骤 [ref: facts/letta-001.md]。

Letta 的第二个关键设计是 **Agent 显式编辑记忆**。Agent 通过 `core_memory_append` 和 `core_memory_replace` 工具直接修改自己的 Block [ref: facts/letta-001.md]。这不是隐式的「模型自己决定记住什么」，而是显式的「Agent 用工具写入记忆」。操作是可审计的——每次 append/replace 都有精确的记录，用户可以看到 Agent 在什么时候、为什么修改了记忆。

Letta 继承了 MemGPT 论文中的 **OS 式记忆四级分层** [ref: facts/letta-001.md]：

| 层级 | OS 类比 | 特性 |
|------|---------|------|
| Core Memory | 寄存器/CPU 缓存 | 常驻上下文窗口，Agent 可直接编辑 |
| Recall Memory | 主存（RAM） | 近期对话历史，分页进出 |
| Archival Memory | 外存（磁盘） | 长期存储，需要显式检索 |
| Summary Memory | 交换区/缓存摘要 | 对长期记忆的压缩摘要 |

这种分层的工程意义在于：Agent 的上下文窗口是一个**精确到 token 的有限资源**，Letta 的 `ContextWindowOverview` 类持续跟踪系统 prompt、工具定义、消息列表和各级记忆占用的 token 数 [ref: facts/letta-001.md]。当 Core Memory 接近上限时，Agent 必须主动决定将哪些内容移到 Archival Memory——这与操作系统在内存不足时将页面换出到磁盘的决策逻辑同构。

Letta 的适用场景可以概括为：**从零构建有状态 Agent**。如果你的系统设计要求 Agent 拥有自我认知（Persona Block）、用户画像（Human Block）、文件记忆（FileBlock），并且 Agent 需要主动管理自己的认知资源，Letta 的架构假设与你的需求对齐。截至 2026 年 4 月，Letta 拥有 22,348 个 star [ref: facts/letta-001.md]。

### §5.4 两条道路的五维对照

Mem0 和 Letta 的差异不是实现细节的不同，而是「记忆在 Agent 系统中应处于什么位置」的根本分歧。以下五个维度展示了这种分歧的工程后果。

| 维度 | Mem0（外部独立层） | Letta（核心架构抽象） |
|------|-------------------|----------------------|
| **记忆位置** | 外部向量数据库，检索后注入 | 上下文窗口保留区，直接常驻 |
| **写入方式** | LLM 自动提取（ADD-only） | Agent 显式工具调用（append/replace） |
| **可控性** | 低（由 extraction prompt 决定） | 高（用户可见 Block，Agent 显式编辑） |
| **检索模型** | 多信号融合（语义+BM25+实体） | OS 式分层（Core/Recall/Archival/Summary） |
| **集成方式** | API 调用，框架无关 | 平台原生，Agent 必须基于 Letta 构建 |

**记忆位置的差异**决定了系统设计的耦合度。Mem0 作为独立服务，可以被任何框架调用，但它的记忆「不在」Agent 的上下文中——每次对话前需要一次检索调用，将相关记忆注入 prompt。Letta 的记忆「在」上下文中，Agent 每次推理都能看到自己的 Block，没有额外的检索延迟，但这也意味着 Agent 必须运行在 Letta 的平台上。

**写入方式的差异**决定了「谁控制记忆」。Mem0 的记忆内容由 LLM 的提取 prompt 决定，开发者通过调整 prompt 间接控制提取行为，但无法精确干预某条对话是否被提取为记忆。Letta 的记忆内容由 Agent 的工具调用决定，Agent 明确知道自己在写入什么——这是一种「自我认知」的架构表达。

**可控性的差异**决定了系统的可解释性。Mem0 的 `history()` 方法可以查看单条记忆的变更时间线 [ref: facts/mem0-001.md]，但开发者难以解释「为什么这条记忆被提取了」。Letta 的 Block 变更是显式工具调用的结果，每次变更都有明确的操作者和操作意图——Agent 在修改自己的记忆时，就像程序员在修改代码一样，行为是可追踪的。

### §5.5 独立记忆层的工程意义

Mem0 和 Letta 的崛起——以及它们与框架内置记忆方案的显著差异——揭示了一个更深层的技术趋势：**记忆正在从「框架附属功能」升级为「可独立演进的基础设施层」**。

这个趋势的意义可以从三个角度理解。

**第一，专业化带来的性能优势。** Mem0 的 benchmark 数据证明了这一点：专用记忆层在 LoCoMo 长程对话评估中得分 91.6，LongMemEval 得分 93.4 [ref: facts/mem0-001.md]。这些数字不是「比框架内置方案好一点」的边际改进，而是「接近人类水平」的质变。当一个功能足够重要、足够复杂时，把它从通用框架中抽离出来，由专门团队持续优化，是软件工程的普遍规律——正如数据库从应用代码中抽离、搜索引擎从网站中抽离一样。

**第二，解耦带来的架构灵活性。** 框架内置记忆方案的一个隐性成本是「锁定」。CrewAI 的记忆子系统只能与 CrewAI 一起使用，LangGraph 的 checkpoint 只能与 LangGraph 一起使用。Mem0 的框架无关设计打破了这种锁定——同一个 Mem0 实例可以同时为 LangGraph 工作流和自建 Agent 提供记忆服务。Letta 虽然平台锁定，但它的锁定在另一个维度：它锁定的不是「记忆技术」，而是「Agent 架构」——选择 Letta 意味着选择了一套关于「有状态 Agent 怎样构建」的完整假设。

**第三，概念澄清带来的设计清晰度。** 独立记忆层项目的存在本身，就是对框架内置方案概念混淆的一种纠正。当 Mem0 明确自称 "memory layer" 而不是 "RAG system" 或 "vector database" 时，它在向社区传递一个信号：记忆有自己的语义边界。当 Letta 把记忆定义为 "reserved section of the LLM's context window" 时，它在向社区传递另一个信号：记忆的位置选择本身就是架构决策。这些清晰的语义声明，与框架 README 中模糊的 "comprehensive memory" 形成了对比。

### §5.6 结论

Mem0 和 Letta 代表了两条不相交但互补的道路。**Mem0 回答的是「如何为已有系统添加记忆」**，它的解耦设计、多信号检索和 ADD-only 策略，使记忆成为可以独立采购和演进的基础设施。**Letta 回答的是「如何从零构建以记忆为核心的 Agent」**，它的 Block 抽象、OS 式分层和 Agent 自编辑机制，使记忆成为 Agent 行为的第一驱动力。

对工程决策的直接影响是：**不要在框架内置记忆方案上过度投资**。框架内置的 memory/knowledge/rag 子系统适合原型验证和简单场景，但当你的 Agent 需要维护跨 session 的用户画像、处理冲突信息、或者让 Agent 主动管理自己的认知资源时，引入独立记忆层是更可持续的选择。

选择 Mem0 还是 Letta，取决于你的 Agent 的架构起点：如果 Agent 已经用某个框架（LangGraph、CrewAI 等）搭建完成，Mem0 的外挂模式成本更低；如果 Agent 尚在架构设计阶段，且「自我认知」和「主动记忆管理」是核心需求，Letta 的内建模式语义更完整。

> **图 5：Mem0（外部记忆层）vs Letta（in-context Block）架构对比**
>
> 左右两个并列架构图。左侧 Mem0：Agent 运行时 → API 调用 → Mem0 服务 → 向量数据库 → 检索结果 → 注入 Agent 上下文。标注「框架无关、多信号检索、ADD-only」。右侧 Letta：Agent 运行时内置 Block 保留区 → Core/Recall/Archival/Summary 四级分层 → Agent 通过工具直接编辑 Block。标注「平台原生、OS 式分层、显式编辑」。底部箭头双向标注「互补而非竞争」。提示词详见 `image-prompts/agent-memory-misconceptions.md` 图 5。
