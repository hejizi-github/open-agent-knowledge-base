---
title: "五极争霸：开源 Agent 框架的坐标系与抉择"
slug: five-pole-agent-frameworks
date: 2026-04-28
target_word_count: "18,000~20,000"
tags: ["Agent 框架", "CrewAI", "LangGraph", "smolagents", "AutoGen", "MAF", "架构对比", "开源项目"]
description: "基于源码级事实对比 CrewAI、LangGraph、smolagents、AutoGen 与 Microsoft Agent Framework，构建五维坐标系决策框架，揭示继承与断裂的设计谱系。"
source_refs:
  - facts/crewai-001.md
  - facts/langgraph-001.md
  - facts/smolagents-001.md
  - facts/autogen-001.md
  - facts/maf-001.md
  - methodology/deep-tech-essay-agent-architecture-001.md
  - methodology/reverse-anthropic-building-effective-agents.md
  - methodology/reverse-langchain-what-is-an-agent.md
  - methodology/inheritance-breakdown-matrix.md
image_prompts: image-prompts/five-pole-agent-frameworks.md
license: CC BY-SA 4.0
---

# 五极争霸：开源 Agent 框架的坐标系与抉择

> 目标读者：有经验的后端/AI 工程师、技术负责人、开源项目维护者
> 预估全文 18,000~20,000 字
> 图片提示词包：[`image-prompts/five-pole-agent-frameworks.md`](../../image-prompts/five-pole-agent-frameworks.md)

---

## §0 摘要（~1,200 字，占 6%）

**核心断言**：
- 五个框架的 GitHub star 数排名（AutoGen 57.5K > CrewAI 50.1K > LangGraph 30.6K > smolagents 26.9K > MAF 9.9K）与"你的项目该选谁"完全无关。
- 大多数技术选型文章把问题错配为"五选一排序题"，但真实决策需要"五维坐标系"——每个框架占据不同的架构范式、控制流显式程度、生态锁定深度和生产就绪梯度。
- 本文基于源码级事实和官方文档，构建一个可操作的决策坐标系，并首次系统梳理 Microsoft Agent Framework 与 AutoGen 之间的"继承/断裂矩阵"——纠正中文社区"MAF = AutoGen 改名"的普遍误读。

**三个反直觉发现**：
1. CrewAI 的 `Process` 抽象仅 11 行代码（2 个 enum 值），真正的编排复杂度分散在 15+ 子系统中——"lean"宣传与 519 个核心文件的现实之间存在张力 [ref: facts/crewai-001.md §Process 抽象的现实]。
2. MAF 的 Python/C# 代码量接近 1:1（50% vs 45%），与 AutoGen 的 64:26 形成鲜明对比——这不是"AutoGen 换皮"，而是真正双语言优先的产品级重构 [ref: facts/maf-001.md §代码分布]。
3. smolagents 的 "~1,000 行"口号与实际 1,814 行的差距，LangGraph 518 MB 仓库与 smolagents 7.3 MB 的体积差，CrewAI 15+ 子系统的功能膨胀——"极简框架"在功能压力下的设计张力是五个项目共同面临的结构性困境。

---

## §1 开头钩子：Star 数排名是一个陷阱（~1,500 字，占 8%）

### §1.1 一个被数字误导的问题
- 国内技术社区最常见的 Agent 框架讨论格式："AutoGen 57K star，是不是最稳的？""CrewAI 50K star，为什么比 LangGraph 高？"
- 这个数字对比预设了一个错误前提：star 数 = 成熟度 = 适合度。
- 反直觉事实：AutoGen 拥有最高 star 数，但已官宣维护模式（2026-04-06），微软推荐迁移至 MAF [ref: facts/autogen-001.md §项目身份]。MAF 仅 9.9K star，却是微软官方产品团队主推的活跃框架 [ref: facts/maf-001.md §项目身份]。

### §1.2 两个被忽略的非线性关系
- **Star 数与时间的关系**：CrewAI（2023-10 创建，2.5 年）比 LangGraph（2023-08 创建，1.8 年）早 2 个月，但 star 高出 64%。这反映的是"角色驱动 API"的易传播性，而非技术优越性。
- **Star 数与代码量的关系**：smolagents 仅 5 个月历史已达 26.9K star，增速超过所有前辈，但核心代码仅 1,814 行。高 star/代码量比可能意味着"概念共鸣"而非"生产依赖"。

### §1.3 本文的替代方案：五维坐标系
- 不回答"哪个最好"，而是提供五个维度的定位工具。
- 预告坐标系：控制流显式度 × 角色语义深度 × 生态锁定强度 × 跨语言支持 × 生产就绪梯度。

---

## §2 定义与边界：从"五选一"到"五维坐标系"（~1,800 字，占 10%）

### §2.1 "Agent 框架"定义困境的升级
- 承接第一篇（smolagents-vs-langgraph）的光谱概念，但升级：单维"控制流显式度"不足以描述五个项目的差异。
- 需要五个独立维度，每个维度上项目分布不同。

### §2.2 五维坐标系定义

| 维度 | 左端 | 右端 | 度量方式 |
|------|------|------|---------|
| **控制流显式度** | 黑盒 ReAct（框架决定） | 白盒状态图（开发者决定） | 开发者需要显式定义的控制流节点比例 |
| **角色语义深度** | 无角色概念 | 角色即第一公民（role/goal/backstory） | 框架 API 中角色相关字段的丰富度 |
| **生态锁定强度** | 零锁定，可随意替换 | 深度绑定商业平台 | 核心功能对第三方商业服务的依赖度 |
| **跨语言支持** | 单语言 | 多语言运行时互操作 | 官方支持的语言数及运行时集成深度 |
| **生产就绪梯度** | 原型/实验工具 | 企业级部署平台 | 持久化、可观测性、安全沙箱、托管方案完备度 |

### §2.3 每个维度上的五极定位（预告图）
- 用表格给出五个项目在每个维度上的大致位置（不展开论证，留到 §4）。

---

## §3 控制流显式光谱：五个项目的控制流设计解剖（~3,500 字，占 19%）

### §3.1 光谱左端：smolagents（黑盒 ReAct）
- `CodeAgent` 的 ReAct loop 完全封装在 `agents.py` 内。
- 开发者只能定义工具列表和初始任务，不能干预 loop 的每一步。
- 当 loop 失败时，调试抓手有限（只能通过 `verbosity` 查看日志）。
- **When to use**：快速原型、单 Agent 任务、模型能力足够强（GPT-4/Claude 级别）。
- **When NOT to use**：需要精确控制执行路径、多 Agent 协作、人机交互介入点。

### §3.2 光谱左中：CrewAI（分布式控制流）
- Crew 层：`Process` enum 仅有 `sequential`/`hierarchical`（11 行代码），看起来极简 [ref: facts/crewai-001.md §Process 抽象的现实]。
- 但真正的控制流分散在三处：
  1. Agent delegation 工具（`DelegateWorkTool`/`AskQuestionTool`）——Agent 之间的动态委托
  2. Flow 框架（`@start`/`@listen`/`@router`）——事件驱动路由，3,572 行 [ref: facts/crewai-001.md §两种执行模式]
  3. Task `context` 依赖链——显式前置任务输出引用
- **关键洞察**：CrewAI 没有统一的控制流抽象，控制流是"分布式"的——这与 LangGraph 的集中式状态图形成鲜明对比。
- **When to use**：角色分工明确的多 Agent 协作、需要事件驱动流程的企业场景。
- **When NOT to use**：需要统一状态视角的复杂工作流（状态分散在 Agent 工具、Flow 装饰器和 Task 依赖中）。

### §3.3 光谱中右：AutoGen（Actor 模型消息传递）
- Core API 基于 Actor 模型：每个 Agent 是一个 Actor，通过异步消息传递通信 [ref: facts/autogen-001.md §4.1]。
- AgentChat API 提供预设团队模式：RoundRobin/Selector/GraphFlow/MagenticOne [ref: facts/autogen-001.md §4.2]。
- 控制流不是由开发者显式画图，而是由 Team 的调度策略决定——比 CrewAI 更集中，比 LangGraph 更隐式。
- **注意**：AutoGen 已维护模式，本节主要作为 MAF 的前置对照。

### §3.4 光谱右端：LangGraph（显式状态机图）
- 承接第一篇的详细分析，简要回顾：Pregel 引擎、nodes/edges/state channels、checkpointing。
- 强调：LangGraph 要求开发者显式定义每一个状态转换——这是五个项目中控制流最显式的。

### §3.5 光谱新玩家：MAF（分层控制流）
- Tier 0：基础 Agent API（`Agent` + `ai_function`）——类似 smolagents 的极简入口。
- Tier 1：高级组件（vector_data, observability）——可选增强。
- Tier 2：厂商连接器（`agent_framework.openai` 等）——按 vendor 分组 [ref: facts/maf-001.md §4.1]。
- Orchestrations 包：Sequential/Concurrent/Handoff/GroupChat/Magentic Builder——比 AutoGen 更丰富，比 CrewAI 更集中 [ref: facts/maf-001.md §4.3]。
- Workflows：原生 Graph-based + checkpointing + time-travel——AutoGen 所不具备的能力 [ref: facts/maf-001.md §4.4]。
- **When to use**：需要分层控制（简单任务用 Tier 0，复杂编排用 Builder，精确控制用 Workflow）。
- **When NOT to use**：项目极新（2025-04 创建），orchestrations 和 durabletask 包仍为 pre-release [ref: facts/maf-001.md §10]。

> **图 1 插入位置**：五项目在"控制流显式度"光谱上的定位图（见 image-prompts 图 1）。

---

## §4 角色语义深度：从"无角色"到"角色即架构"（~2,500 字，占 14%）

### §4.1 光谱左端：smolagents / LangGraph（无角色概念）
- smolagents：Agent = 工具列表 + ReAct loop。没有 role/goal/persona 概念。
- LangGraph：Agent = 图中的一个节点函数。角色语义完全由开发者自己在节点函数内实现。

### §4.2 光谱右端：CrewAI（角色三元组）
- `Agent(role, goal, backstory)` 是 CrewAI 最具辨识度的 API 设计 [ref: facts/crewai-001.md §1]。
- 角色描述被注入 system prompt，驱动 LLM 行为。
- **反共识点**：角色语义是 API 层的用户体验优化，而非执行层的架构创新——底层仍是 ReAct loop（与 smolagents 无本质差异） [ref: facts/crewai-001.md §反共识点]。
- **风险**：自然语言角色描述的效果不可验证，不同 LLM 对相同角色描述的理解差异可能导致不可预期行为。

### §4.3 中间地带：AutoGen / MAF
- AutoGen：Agent 有 `name` 和 `description`，但无 CrewAI 式的三元组。
- MAF：`Agent(name, instructions, tools)` —— `instructions` 相当于简化的角色描述，但无 `goal`/`backstory` 的强制结构化。

### §4.4 角色语义与框架适用性的关系
- 角色语义越深，框架越适合"模拟人类团队协作"场景（客服团队、内容创作团队）。
- 角色语义越浅，框架越适合"自动化流水线"场景（数据处理、工具调用链）。
- 多数实际项目介于两者之间——这正是 CrewAI 试图通过 Flow 框架扩展的原因。

> **图 2 插入位置**：角色语义深度光谱与适用场景映射图（见 image-prompts 图 2）。

---

## §5 生态锁定强度：开源核心与商业闭环的博弈（~2,200 字，占 12%）

### §5.1 零锁定极：smolagents（Hugging Face 生态）
- 无商业平台绑定。Hugging Face Hub 工具免费，模型支持通过 LiteLLM 覆盖 100+ 提供商。
- License：Apache-2.0（最商业化友好）。

### §5.2 轻度锁定：LangGraph（LangSmith 诱导）
- LangGraph 本身 MIT 许可，开源核心完整。
- 但完整的可观测性、部署、团队协作锁定在 LangSmith 商业平台 [ref: facts/langgraph-001.md §生态位与商业闭环]。
- "可以不依赖 LangChain"的声明与实际文档/示例的耦合之间存在张力 [ref: facts/langgraph-001.md §已知限制]。

### §5.3 中度锁定：CrewAI（Cloud 平台诱导）
- CrewAI Cloud / AMP Suite 提供 tracing、控制平面、企业集成 [ref: facts/crewai-001.md §维护活跃度评估]。
- 开源版本功能完整，但企业级可观测性天然倾向商业平台。
- 独立宣言（"completely independent of LangChain"）与内部 LangGraph adapter 的并存——统一入口策略 [ref: facts/crewai-001.md §反共识点]。

### §5.4 深度锁定：MAF（Microsoft Foundry 默认）
- Quickstart 示例默认使用 Azure CLI + Microsoft Foundry [ref: facts/maf-001.md §10]。
- README 含第三方系统免责声明（使用非 Azure 模型需自行承担风险）。
- 产品矩阵导向最明显：DurableTask、Azure Functions、ASP.NET Core 托管、Azure AI Search/Cosmos 内存——全是微软生态 [ref: facts/maf-001.md §7]。
- **反共识点**：这不是缺陷，而是明确的产品定位——MAF 是微软 Azure AI 平台的客户端框架，不是中立的通用工具。

### §5.5 锁定光谱的决策含义
- 锁定强度 ≠ 好坏。锁定强意味着生态深度（MAF 的原生 Azure 集成），锁定弱意味着自由度（smolagents 的任意模型/工具）。
- 决策关键是：你的组织是否已经在对应生态中？

> **图 3 插入位置**：五项目生态锁定强度光谱与适用组织类型映射（见 image-prompts 图 3）。

---

## §6 继承与断裂矩阵：MAF 不是 AutoGen 的改名（~2,800 字，占 16%）

### §6.1 中文社区的普遍误读
- 多数中文文章将 MAF 描述为"AutoGen 的继任者""微软把 AutoGen 改了个名"。
- 这个误读源于：同一组织（Microsoft）、相似领域（多 Agent 框架）、AutoGen README redirect 至 MAF、概念命名相似（Agent/GroupChat/Tool）。
- 但源码级对比揭示了一幅更复杂的图景。

### §6.2 继承关系（5 处）

| 继承方面 | AutoGen 形态 | MAF 形态 | 证据 |
|---------|-------------|---------|------|
| 编排模式 | `MagenticOneGroupChat` | `MagenticBuilder` | 命名完全一致，概念延续 [ref: facts/maf-001.md §4.3] |
| 编排模式 | `SelectorGroupChat` | `GroupChatBuilder` | 命名一致，选择器驱动群聊 [ref: facts/maf-001.md §4.3] |
| 双语言 | Python + .NET（64:26） | Python + .NET（50:45） | 跨语言设计延续，但比例更均衡 [ref: facts/maf-001.md §3] |
| Actor 模型 | Core API 异步消息传递 | 运行时设计延续 | 架构思想继承 [ref: facts/maf-001.md §9] |
| MCP 支持 | `McpWorkbench` | 原生 MCP 客户端 | 协议支持延续 [ref: facts/maf-001.md §9] |

### §6.3 断裂/重构（8 处）

| 断裂方面 | AutoGen | MAF | 意义 |
|---------|---------|-----|------|
| 包结构 | Strict 三层（Core/Chat/Ext） | 扁平 Tier 0/1/2 + namespace packages | 从"分层架构"转向"开发者体验优先的扁平导入" [ref: facts/maf-001.md §4.1] |
| 工作流 | 无原生图工作流 | Graph-based + checkpoint + time-travel | 直接对标 LangGraph 能力 [ref: facts/maf-001.md §4.4] |
| 持久化 | 无内置持久化 | DurableTask 原生集成 | 企业级故障恢复能力 [ref: facts/maf-001.md §4.5] |
| 协议 | 仅 MCP | MCP + A2A + AG-UI | 从单协议到多协议战略 [ref: facts/maf-001.md §5.4] |
| UI | AutoGen Studio（非生产就绪） | DevUI（集成开发调试） | 从实验工具到生产级开发环境 [ref: facts/maf-001.md §6.1] |
| 代码执行 | DockerCommandLineCodeExecutor | CodeAct + Hyperlight 沙箱 | 从容器隔离到轻量级虚拟化 [ref: facts/maf-001.md §6.3] |
| 中间件 | 无中间件概念 | 原生 Middleware 系统 | 请求/响应管道的显式控制 [ref: facts/maf-001.md §5.3] |
| License | CC-BY-4.0 | MIT | 从知识共享到商业化友好 [ref: facts/maf-001.md §1] |

### §6.4 "研究院 → 产品团队"的组织断裂
- AutoGen 发起方：Microsoft Research（研究院）。
- MAF 发起方：Microsoft 官方产品团队（非研究院独立项目）。
- 这个组织断裂解释了 8 处技术断裂的根本原因：研究院追求架构创新（Actor 模型、严格分层），产品团队追求开发者体验（扁平导入、默认 Azure 集成、Tiered API）。
- **核心结论**：MAF 是 AutoGen 的"产品化重构"，而非简单 rebranding。它继承了概念，但用完全不同的工程哲学重新实现。

> **图 4 插入位置**：继承/断裂矩阵可视化图（见 image-prompts 图 4）。

---

## §7 跨维度全景对比表（~1,500 字，占 8%）

### §7.1 16 维对比表

| 维度 | CrewAI | LangGraph | smolagents | AutoGen | MAF |
|------|--------|-----------|------------|---------|-----|
| Stars (2026-04) | 50,114 | 30,593 | 26,939 | 57,512 | 9,885 |
| 创建时间 | 2023-10 | 2023-08 | 2024-12 | 2023-08 | 2025-04 |
| 当前状态 | 活跃 | 活跃 | 活跃 | **维护模式** | **活跃** |
| License | MIT | MIT | Apache-2.0 | CC-BY-4.0 | MIT |
| 核心代码量 | 519 文件 / 8.4MB | 518 MB 仓库 | ~1,800 行 | ~4.3MB Python | ~11.9MB Python |
| 主语言 | Python | Python | Python | Python (64%) / C# (26%) | Python (50%) / C# (45%) |
| 控制流范式 | 分布式（Agent工具+Flow+Task依赖） | 显式状态图 | 黑盒 ReAct | Actor消息+Team策略 | 分层（Tier 0/1/2 + Builder + Workflow） |
| 角色语义 | role/goal/backstory 三元组 | 无（节点函数自实现） | 无 | name/description | name/instructions |
| 编排模式 | sequential/hierarchical/Flow | 任意 nodes/edges | 单 Agent | RoundRobin/Selector/GraphFlow/Magentic | Sequential/Concurrent/Handoff/GroupChat/Magentic |
| 持久化 | State/Checkpoint + Memory | 原生 checkpointing | 无 | 无 | DurableTask 原生 |
| 工作流能力 | Flow（事件驱动） | 原生状态图 | 无 | GraphFlow（有限） | Graph + checkpoint + time-travel |
| 协议支持 | MCP + A2A | MCP | MCP | MCP | MCP + A2A + AG-UI |
| 安全沙箱 | 无内置 | 依赖部署环境 | E2B/Docker/WASM | Docker（默认） | CodeAct/Hyperlight |
| 商业平台 | CrewAI Cloud | LangSmith | 无 | 无 | Microsoft Foundry/Azure |
| 人机交互 | HumanFeedbackResult | 原生 interrupt | 无内置 | 无内置 | 原生 hitl |
| 最新版本 | 1.14.3 (2026-04-24) | 1.1.10 (2026-04-27) | 1.24.0 (2026-01-16) | 0.7.5 (2025-09-30) | python-1.2.0 / dotnet-1.3.0 (2026-04-24) |

### §7.2 从表格中读取的隐藏模式
- **模式 1**：活跃项目的 release 频率都极高（CrewAI 每周 patch，LangGraph 几乎每日，MAF 每 2-3 天），只有 smolagents（~3.5 个月）和 AutoGen（维护模式）偏慢。
- **模式 2**：角色语义深度与控制流显式度呈负相关——CrewAI 角色最深但控制流最分散，LangGraph 控制流最显式但无角色概念。
- **模式 3**：生态锁定强度与发起方商业模式直接相关——CrewAI（创业公司）/LangGraph（LangChain 公司）/MAF（微软）都有商业闭环，只有 smolagents（HF 非营利生态）和 AutoGen（研究院）无直接商业绑定。

> **图 5 插入位置**：五维雷达图可视化（见 image-prompts 图 5）。

---

## §8 设计取舍与失败模式（~2,000 字，占 11%）

### §8.1 五个项目各自的结构性张力

**CrewAI："Lean"宣传 vs 功能膨胀**
- 519 个核心文件、15+ 子系统与 "lean, lightning-fast" 口号之间的落差 [ref: facts/crewai-001.md §代码量声明 vs 实际]。
- Process 抽象过薄（11 行）导致编排逻辑分散，缺乏统一视角 [ref: facts/crewai-001.md §Process 抽象的现实]。
- Flow 与 LangGraph 功能重叠，但实现方式不同（事件驱动 vs 状态图），形成内部竞争。

**LangGraph：显式控制的认知税**
- 简单任务上的过度工程化风险——Anthropic "简单 > 复杂"警告的直接冲突 [ref: facts/langgraph-001.md §已知限制]。
- Monorepo 多包独立版本导致的依赖管理复杂度。

**smolagents：极简口号下的代码膨胀**
- "~1,000 行"与实际 1,814 行的差距损害技术可信度 [ref: facts/smolagents-001.md §代码量声明 vs 实际]。
- LocalPythonExecutor 的安全幻觉——用户可能误将本地执行器当作沙箱 [ref: facts/smolagents-001.md §已知限制]。
- 2 人核心维护团队 vs 517 open issues 的长期可维护性风险。

**AutoGen：维护模式的遗产问题**
- 已停止功能开发，社区维护的安全修复力度存疑。
- GraphFlow callable conditions 不可序列化等实验性功能的稳定性问题。

**MAF：极新项目的不稳定性**
- Orchestrations / DurableTask / DevUI 等核心扩展包仍为 pre-release [ref: facts/maf-001.md §10]。
- 默认锁定 Microsoft Foundry，对非 Azure 用户存在隐性门槛。
- CodeAct ADR 0024 仍为 proposed 状态，尚未落地 [ref: facts/maf-001.md §10]。

### §8.2 跨项目共同困境
- "极简框架"在功能扩展压力下的设计张力：五个项目都在某处声称"简单"，但代码量/子系统数都在增长。
- 这个困境的深层原因：Agent 框架的边界本身在模糊化——它们越来越多地承担工作流引擎、可观测性平台、部署工具的职责。

---

## §9 决策框架：何时用 / 何时不用（~1,800 字，占 10%）

### §9.1 决策树（基于五维坐标系）

**第一层：你的核心需求是什么？**
- A. 快速验证一个 Agent 想法 → smolagents
- B. 模拟人类团队协作（角色分工） → CrewAI
- C. 精确控制每一步状态流转 → LangGraph
- D. 微软/Azure 生态深度集成 → MAF
- E. 维护已有 AutoGen 项目 → 迁移至 MAF（微软推荐）

**第二层：你对生态锁定的容忍度？**
- 零容忍 → smolagents（Apache-2.0，无商业平台）
- 可接受轻度诱导 → LangGraph（LangSmith 可选）/ CrewAI（Cloud 可选）
- 已在 Azure 生态 → MAF（原生集成是优势而非负担）

**第三层：你的团队规模和技能栈？**
- 小团队/快速迭代 → smolagents（认知税最低）
- 有 .NET 背景 → MAF（真正的 Python/C# 双语言）
- 有图论/状态机经验 → LangGraph
- 有角色扮演/游戏化需求 → CrewAI

### §9.2 "何时甚至不该用框架"
- 承接 Anthropic 方法论：如果你只需要单个 LLM 调用 + 少数工具调用，任何框架都是过度工程。
- 具体指标：任务步骤 < 3 步、无需状态共享、无需人机交互、无需持久化 → 直接用 OpenAI/Anthropic API + 函数调用即可。

---

## §10 总结：三条可执行原则（~800 字，占 4%）

1. **不要根据 star 数选框架**——AutoGen 57K star 已维护模式，MAF 9.9K star 才是微软主推。Star 数反映的是传播度，不是适合度。
2. **先确定控制流显式度需求，再确定角色语义深度需求**——这两个维度基本决定了框架选择范围。其他维度（生态锁定、跨语言、生产就绪）用于在候选集中做排除。
3. **框架是加速器，不是必需品**——Agent 框架的边界正在模糊化（向工作流引擎、可观测性平台、部署工具扩张），但底层始终是 LLM + 工具调用。理解底层后，框架才是可选的加速器。

---

## 附录（正文外，不纳入字数统计）

### 附录 A：五项目版本演进时间线
- 横向时间线对比图（2023-08 至 2026-04）。

### 附录 B：继承/断裂矩阵方法论
- 如何系统分析"继任者"框架与"前身"框架的关系。
- 方法论沉淀文件：`methodology/inheritance-breakdown-matrix.md`。

### 附录 C：图片来源与提示词清单
- 见 `image-prompts/five-pole-agent-frameworks.md`。

---

## 图片占位符汇总

| 图号 | 章节 | 标题 | 提示词位置 |
|------|------|------|-----------|
| 图 1 | §3.5 | 控制流显式光谱五极定位 | image-prompts 图 1 |
| 图 2 | §4.4 | 角色语义深度光谱与场景映射 | image-prompts 图 2 |
| 图 3 | §5.5 | 生态锁定强度光谱与组织映射 | image-prompts 图 3 |
| 图 4 | §6.4 | 继承/断裂矩阵可视化 | image-prompts 图 4 |
| 图 5 | §7.2 | 五维雷达图 | image-prompts 图 5 |
| 图 6 | §8.2 | "极简框架"的设计张力循环 | image-prompts 图 6 |
| 图 7 | 封面 | 五极争霸概念封面 | image-prompts 封面 |
