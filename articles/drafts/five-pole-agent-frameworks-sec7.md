## §7 跨维度全景对比表（~1,500 字）

前四节（§3 至 §6）从控制流、角色语义、生态锁定和继承断裂四个角度分别拆解了每个框架。本节将这四个角度以及另外十二个可量化维度汇总为一张 16 维对比表，并从中提取三个不依赖主观评价就能从数据中读出的隐藏模式。

---

### §7.1 16 维对比表

下表所有数据均来自 2026 年 4 月 28 日 GitHub API 和官方文档的直接测量，不引用二手解读。

| 维度 | CrewAI | LangGraph | smolagents | AutoGen | MAF |
|------|--------|-----------|------------|---------|-----|
| **Stars** | 50,114 [ref: facts/crewai-001.md] | 30,593 [ref: facts/langgraph-001.md] | 26,939 [ref: facts/smolagents-001.md] | 57,512 [ref: facts/autogen-001.md] | 9,885 [ref: facts/maf-001.md] |
| **创建时间** | 2023-10 [ref: facts/crewai-001.md] | 2023-08 [ref: facts/langgraph-001.md] | 2024-12 [ref: facts/smolagents-001.md] | 2023-08 [ref: facts/autogen-001.md] | 2025-04 [ref: facts/maf-001.md] |
| **当前状态** | 活跃 | 活跃 | 活跃 | **维护模式** [ref: facts/autogen-001.md] | **活跃** |
| **License** | MIT [ref: facts/crewai-001.md] | MIT [ref: facts/langgraph-001.md] | Apache-2.0 [ref: facts/smolagents-001.md] | CC-BY-4.0 [ref: facts/autogen-001.md] | MIT [ref: facts/maf-001.md] |
| **核心代码量** | 519 文件 / 8.4 MB [ref: facts/crewai-001.md] | 518 MB 仓库 [ref: facts/langgraph-001.md] | ~1,800 行 [ref: facts/smolagents-001.md] | ~4.3 MB Python [ref: facts/autogen-001.md] | ~11.9 MB Python [ref: facts/maf-001.md] |
| **主语言** | Python | Python | Python | Python (64%) / C# (26%) [ref: facts/autogen-001.md] | Python (50%) / C# (45%) [ref: facts/maf-001.md] |
| **控制流范式** | 分布式（Agent 工具 + Flow + Task 依赖）[ref: facts/crewai-001.md] | 显式状态图 [ref: facts/langgraph-001.md] | 黑盒 ReAct [ref: facts/smolagents-001.md] | Actor 消息 + Team 策略 [ref: facts/autogen-001.md] | 分层（Tier 0/1/2 + Builder + Workflow）[ref: facts/maf-001.md] |
| **角色语义** | role/goal/backstory 三元组 [ref: facts/crewai-001.md] | 无（节点函数自实现）[ref: facts/langgraph-001.md] | 无 [ref: facts/smolagents-001.md] | name/description [ref: facts/autogen-001.md] | name/instructions [ref: facts/maf-001.md] |
| **编排模式** | sequential/hierarchical/Flow [ref: facts/crewai-001.md] | 任意 nodes/edges [ref: facts/langgraph-001.md] | 单 Agent [ref: facts/smolagents-001.md] | RoundRobin/Selector/GraphFlow/Magentic [ref: facts/autogen-001.md] | Sequential/Concurrent/Handoff/GroupChat/Magentic [ref: facts/maf-001.md] |
| **持久化** | State/Checkpoint + Memory [ref: facts/crewai-001.md] | 原生 checkpointing [ref: facts/langgraph-001.md] | 无 [ref: facts/smolagents-001.md] | 无 [ref: facts/autogen-001.md] | DurableTask 原生 [ref: facts/maf-001.md] |
| **工作流能力** | Flow（事件驱动）[ref: facts/crewai-001.md] | 原生状态图 [ref: facts/langgraph-001.md] | 无 [ref: facts/smolagents-001.md] | GraphFlow（有限）[ref: facts/autogen-001.md] | Graph + checkpoint + time-travel [ref: facts/maf-001.md] |
| **协议支持** | MCP + A2A [ref: facts/crewai-001.md] | MCP [ref: facts/langgraph-001.md] | MCP [ref: facts/smolagents-001.md] | MCP [ref: facts/autogen-001.md] | MCP + A2A + AG-UI [ref: facts/maf-001.md] |
| **安全沙箱** | 无内置 [ref: facts/crewai-001.md] | 依赖部署环境 [ref: facts/langgraph-001.md] | E2B/Docker/WASM [ref: facts/smolagents-001.md] | Docker（默认）[ref: facts/autogen-001.md] | CodeAct/Hyperlight [ref: facts/maf-001.md] |
| **商业平台** | CrewAI Cloud [ref: facts/crewai-001.md] | LangSmith [ref: facts/langgraph-001.md] | 无 | 无 | Microsoft Foundry/Azure [ref: facts/maf-001.md] |
| **人机交互** | HumanFeedbackResult [ref: facts/crewai-001.md] | 原生 interrupt [ref: facts/langgraph-001.md] | 无内置 [ref: facts/smolagents-001.md] | 无内置 [ref: facts/autogen-001.md] | 原生 HITL [ref: facts/maf-001.md] |
| **最新版本** | 1.14.3 (2026-04-24) [ref: facts/crewai-001.md] | 1.1.10 (2026-04-27) [ref: facts/langgraph-001.md] | 1.24.0 (2026-01-16) [ref: facts/smolagents-001.md] | 0.7.5 (2025-09-30) [ref: facts/autogen-001.md] | python-1.2.0 / dotnet-1.3.0 (2026-04-24) [ref: facts/maf-001.md] |

这张表格的密度很高，但关键不在于记住每个数字，而在于观察数字之间的结构性关系。以下三个模式全部从上述表格中直接推导，不依赖外部假设。

---

### §7.2 从表格中读取的隐藏模式

**模式一：Release 频率是项目活跃度的领先指标，Star 数是滞后指标**

五个项目的最新版本日期揭示了一条清晰的活跃度分界线。CrewAI 1.14.3 发布于 2026 年 4 月 24 日，LangGraph 1.1.10 发布于 4 月 27 日，MAF python-1.2.0 / dotnet-1.3.0 发布于 4 月 24 日——三个活跃项目的最新 release 距离本文写作均不超过 4 天 [ref: facts/crewai-001.md] [ref: facts/langgraph-001.md] [ref: facts/maf-001.md]。作为参照，CrewAI 的前序版本 1.14.2 发布于 4 月 17 日，中间还穿插了三个 alpha 版本（1.14.3a1-3，4 月 20 日至 22 日），这意味着 CrewAI 在 8 天内发布了 5 个版本 [ref: facts/crewai-001.md]。LangGraph 的子包（prebuilt、checkpoint、cli）各自独立发版，核心仓库的推送记录显示几乎每日都有合并 [ref: facts/langgraph-001.md]。MAF 的双语言版本每 2 至 3 天更新一次 [ref: facts/maf-001.md]。

对比另一端：smolagents 最新版本 v1.24.0 发布于 2026 年 1 月 16 日，距本文写作已过去 3.5 个月 [ref: facts/smolagents-001.md]。AutoGen 的 python-v0.7.5 发布于 2025 年 9 月 30 日，已半年无新版本，且项目已官宣维护模式 [ref: facts/autogen-001.md]。

这条分界线与 star 数的排序完全不一致。AutoGen 以 57,512 star 居首，但已冻结开发；MAF 仅 9,885 star，却是发版最勤的项目之一 [ref: facts/autogen-001.md] [ref: facts/maf-001.md]。对于生产选型，"最近一次 release 距今多少天"比"总 star 数多少"更能反映项目当前的健康状态。

**模式二：角色语义深度与控制流显式度呈负相关**

表格在"角色语义"和"控制流范式"两列上呈现出一个清晰的反比关系。CrewAI 的角色语义最丰富（role/goal/backstory 三元组），但它的控制流最分散——Agent delegation 工具、Flow 事件驱动框架和 Task context 依赖链三个子系统各自独立运作，不存在统一的状态视图 [ref: facts/crewai-001.md]。LangGraph 位于光谱另一端：控制流完全显式（开发者定义每一个 node 和 edge），但角色语义为零——Agent 只是图中的一个可调用函数，框架不感知"角色"概念 [ref: facts/langgraph-001.md]。

smolagents 和 AutoGen 落在中间地带：两者都没有结构化角色定义，控制流也都不完全显式（smolagents 的黑盒 ReAct [ref: facts/smolagents-001.md]，AutoGen 的 Team 调度策略 [ref: facts/autogen-001.md]）。MAF 试图打破这个负相关——它提供了 name/instructions 的轻度角色语义，同时通过 Workflow 层提供显式图控制 [ref: facts/maf-001.md]——但 Workflow 层仍处于 pre-release 状态，这个突破尚未稳定落地 [ref: facts/maf-001.md]。

这个负相关的工程含义是：框架设计者需要在"让开发者用自然语言描述协作"和"让开发者用代码精确控制执行"之间做取舍。两者兼顾在理论上可行，但会显著增加框架复杂度。

**模式三：生态锁定强度与发起方商业模式直接相关**

表格的"商业平台"和"License"两列将五个项目划分为两组。第一组有明确的商业闭环：CrewAI 的 CrewAI Cloud 和 AMP Suite [ref: facts/crewai-001.md]，LangGraph 的 LangSmith [ref: facts/langgraph-001.md]，MAF 的 Microsoft Foundry 和 Azure AI 全家桶 [ref: facts/maf-001.md]。这三者的发起方分别是创业公司（CrewAIInc）、商业化开源公司（LangChain AI）和云厂商（Microsoft），商业模式都包含"开源核心 + 付费托管/可观测性"。

第二组没有直接商业绑定：smolagents 由 Hugging Face 维护，Hugging Face 的核心收入来自模型托管和推理服务，而非 Agent 框架本身 [ref: facts/smolagents-001.md]。AutoGen 由 Microsoft Research 发起，CC-BY-4.0 的许可证甚至不适合直接嵌入商业产品 [ref: facts/autogen-001.md]。

这个相关性的决策含义在于：生态锁定不是技术优劣问题，而是商业结构问题。选择 LangGraph 意味着接受 LangSmith 生态的诱导，选择 MAF 意味着接受 Azure 生态的默认值——这些在对应生态中已经投入的组织眼中是便利，在独立开发者眼中是约束。只有 smolagents 提供了"无商业平台绑定"的选项，代价是缺少官方提供的企业级可观测性和托管方案。

> **图 5 插入位置**：五维雷达图可视化，五个项目在五维雷达图上的相对强弱。详见 `image-prompts/five-pole-agent-frameworks.md` 图 5。
