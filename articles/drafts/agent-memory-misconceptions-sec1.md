# 记忆幻象：Agent 框架的「记忆」承诺与工程现实

## §1 开头钩子：同一个词，七种实现（~1,500 字）

### §1.1 并置原文

让我们做一个简单的实验。打开七个主流 Agent 框架的 GitHub 页面或 README，搜索「memory」这个词，然后把它们的描述并置在一起。

**Mem0** 的仓库描述是：

> "Universal memory layer for AI Agents" [ref: facts/mem0-001.md]

这是一个独立基础设施项目的宣言。Mem0 不依附于任何 Agent 框架，它的目标是成为所有 Agent 的「通用记忆层」。截至 2026 年 4 月，这个项目拥有 54,291 个 star，6,111 个 fork。它的核心代码 `mem0/memory/main.py` 有 3,222 行，`Memory` 类独占约 1,460 行 [ref: facts/mem0-001.md]。这是一个把记忆当作第一公民来设计的项目。

**Letta**（原 MemGPT）的仓库描述是：

> "platform for building stateful agents with advanced memory" [ref: facts/letta-001.md]

「stateful」和「advanced」是两个关键词。Letta 的记忆不是外部存储层，而是 Agent 核心架构的一部分。它的核心抽象是 `Block`——"A Block represents a reserved section of the LLM's context window"。记忆不是被检索进上下文的，记忆本身就是上下文窗口中的保留区域。Letta 有 22,348 个 star，2,372 个 fork [ref: facts/letta-001.md]。

**LangGraph** 的 README 在 "Why use LangGraph?" 一节中列出记忆能力：

> "Short-term memory: working memory within a single session; Long-term memory: persistent memory across sessions" [ref: facts/langgraph-001.md]

LangGraph 用「短期记忆」和「长期记忆」的二分法来组织概念，底层通过 `langgraph-checkpoint` 子包实现持久化。它有 30,593 个 star，5,228 个 fork [ref: facts/langgraph-001.md]。

**CrewAI** 的文档将记忆能力分散在三个子系统中。`memory/` 目录提供 "Unified Memory"（LanceDB/Qdrant 后端），`knowledge/` 目录处理多格式文件源（PDF、CSV、Excel），`rag/` 目录提供 ChromaDB + 20+ embedding providers。CrewAI 没有给出一个统一的「记忆」定义，而是把记忆、知识和 RAG 当作三个并列能力来宣传。它有 50,114 个 star [ref: facts/crewai-001.md]。

**AutoGen** 的记忆能力藏在 Extensions API 的列表中：

> "Memory backends: ListMemory, RedisMemory, Mem0, ChromaDB embeddings" [ref: facts/autogen-001.md]

AutoGen 不提供自己的记忆抽象，而是提供四种后端的适配器。值得注意的是，这四种后端中有三种是外部项目（Redis、Mem0、ChromaDB），一种是内部实现（ListMemory）。AutoGen 有 57,512 个 star [ref: facts/autogen-001.md]，但已于 2026 年 4 月进入维护模式。

**OpenHands** 的文档中没有出现「memory」作为独立子系统的宣传。它的 `State` 对象保存「当前步数、事件历史、长期计划等」，通过 `EventStream` 持久化。OpenHands 有 72,234 个 star，是这七个项目中 star 数最高的 [ref: facts/openhands-001.md]。

**smolagents** 的 README 中几乎没有「memory」这个词。它的核心设计是 `CodeAgent` 和 `ToolCallingAgent`，没有内置持久化记忆机制。开发者如果需要记忆，必须自行实现。smolagents 有 26,939 个 star [ref: facts/smolagents-001.md]。

把这七段描述放在一起，一个无法回避的事实浮现出来：**「memory」这个词在开源 Agent 生态中不是一个技术标准，而是一个营销词汇。** 每个项目都在用它，但每个项目赋予它的含义都截然不同——从 Mem0 的「外部向量存储层」到 Letta 的「上下文窗口保留区」，从 LangGraph 的「执行状态快照」到 CrewAI 的「三子系统并列」，从 AutoGen 的「后端适配器列表」到 OpenHands 的「事件历史记录」，再到 smolagents 的「不存在」。

### §1.2 认知失调：当工程师相信这些描述

这种语义混乱对工程决策的损害不是理论性的。让我们看两个具体场景。

**场景一：选型困惑。** 一个工程师在评估 Agent 框架，看到 LangGraph 宣传「long-term memory」，CrewAI 宣传「Unified Memory」，Mem0 宣传「Universal memory layer」。他的合理推断是：这些框架都「支持记忆」，区别只在实现细节。于是他选择 star 数最高的 LangGraph，以为长期记忆问题已经解决。六个月后他发现，LangGraph 的 long-term memory 是 checkpoint 持久化——能保存执行状态，但不能让 Agent 在跨 session 对话中「记住」用户的偏好。他需要的其实是 Mem0 的语义记忆层或 Letta 的 Block 自编辑机制，但框架的宣传语没有给他做出这个区分的线索 [ref: facts/langgraph-001.md] [ref: facts/mem0-001.md]。

**场景二：概念误用。** 一个团队在 CrewAI 中同时使用 memory、knowledge 和 rag 三个子系统。他们把用户对话历史存入 memory，把产品文档存入 knowledge，把 FAQ 存入 rag。三个月后排查 bug 时发现，这三个子系统的底层都指向同一个 ChromaDB 向量存储，embedding 模型相同，检索逻辑也相同 [ref: facts/crewai-001.md]。「memory 条目」和「knowledge 条目」在数据库层面没有结构差异——它们都是向量 + 文本 + 元数据。三个名词在 API 文档中制造了「我在做三件事」的幻觉，实际上团队在做一件事的三个入口。

这些问题的根源不是某个框架的文档写得不好，而是「memory」这个词本身在 Agent 领域缺乏语义共识。当一个框架说「我们支持记忆」时，它对应的实现属于以下类别之一：

- 对话历史的向量存储（CrewAI memory 子系统）
- 执行状态的 checkpoint 快照（LangGraph long-term memory）
- 上下文窗口中的结构化保留区（Letta Block）
- 外部服务的适配接口（AutoGen Memory backends）
- 事件轨迹的持久化日志（OpenHands EventStream）
- 独立的多层级语义记忆层（Mem0）
- 什么都不指（smolagents）

### §1.3 本文要做什么

本文不教你「如何在框架 X 中启用记忆」，也不做「Mem0 vs Letta 功能对比表」。这些内容易获取且更新快，写进长文只会加速过期。

本文要做的是追问 Agent 记忆系统中的三组深层混淆：**上下文窗口与记忆的混淆**、**检索系统与记忆系统的混淆**、**执行持久化与学习的混淆**。§2 分析为什么 10M token 的上下文窗口不能替代记忆层，用 Mem0 benchmark 数据证明「有信息」不等于「能回忆」。§3 解剖 CrewAI 的 memory/knowledge/rag 三子系统，揭示「三个入口、同一套底层」的概念重叠。§4 区分 LangGraph checkpoint 的「durable execution」与真正的「learnable memory」，追问为什么一个执行恢复机制被包装成了长期记忆。§5 回到架构层面，对比 Mem0 的外部记忆层与 Letta 的 in-context Block 两种设计范式。§6 给出可操作的决策框架。

读完这篇文章，你将获得一套可以复用到任何框架评估的「记忆语义分析」工具——不只是「这个框架能记住什么」，而是「这个框架说的『记忆』在哪个语义层级上运作，以及这种选择对系统设计的隐性约束」。

> **图 1：「memory」一词在七个框架中的语义图谱**
>
> 七个框架的 memory 定义按「存储位置」（外部数据库 vs 上下文窗口）和「编辑方式」（LLM 自动提取 vs Agent 显式编辑）两个维度分布。提示词详见 `image-prompts/agent-memory-misconceptions.md` 图 1。
