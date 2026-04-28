## §9 决策框架：何时用 / 何时不用（~1,800 字）

前五节从控制流、角色语义、生态锁定、继承断裂和设计张力五个角度拆解了五个框架的内在结构。本节把这些结构分析转化为一个可操作的决策流程——不是告诉你"哪个最好"，而是帮你"根据三个问题排除三个候选框架"。

---

### §9.1 三层决策树

**第一层：你的核心需求是什么？**

这个问题排除了"功能错配"——选了一个在错误维度上最强的框架。

- **A. 快速验证一个 Agent 想法，三小时内出原型** → **smolagents**

  smolagents 的认知税最低：定义工具列表、写自然语言任务描述、运行。没有图论概念、没有角色设计、没有状态持久化配置。CodeAgent 的代码执行风格让 LLM 直接写 Python 片段，调试直觉与常规编程一致 [ref: facts/smolagents-001.md §核心架构声明]。代价是控制流完全黑盒——如果原型验证后需要精确控制执行路径，迁移成本较高。

- **B. 模拟人类团队协作，角色分工是核心隐喻** → **CrewAI**

  CrewAI 的 `role`/`goal`/`backstory` 三元组将"团队模拟"作为第一公民 [ref: facts/crewai-001.md §核心架构声明]。客服团队、内容创作流水线、多领域研究小组——凡是"让几个有不同专长的虚拟成员协作"的场景，CrewAI 的 API 设计能直接映射到业务语言。代价是控制流分散在 Agent delegation、Flow 装饰器和 Task 依赖三个独立子系统中，复杂编排时缺乏统一状态视图 [ref: facts/crewai-001.md §两种执行模式]。

- **C. 精确控制每一步状态流转，容错和可审计是硬性要求** → **LangGraph**

  LangGraph 的 Pregel 引擎要求开发者显式定义每一个 node 和 edge，但换来的能力是其他框架不具备的：原生 checkpointing（故障后从任意步骤恢复）、time-travel（回溯到历史状态重放）、human-in-the-loop interrupt（在精确节点暂停等待人工输入）[ref: facts/langgraph-001.md §状态持久化]。金融交易流水线、医疗诊断决策链、合规审计工作流——任何"每一步都必须可追踪、可回滚"的场景，LangGraph 几乎是唯一选项。代价是认知税：开发者必须理解图论概念才能写出第一个工作流 [ref: facts/langgraph-001.md §已知限制与失败模式]。

- **D. 深度集成微软/Azure 生态，已有 Azure AI Search、Cosmos DB、Durable Functions 投资** → **MAF**

  MAF 不是"一个能在 Azure 上运行的通用框架"，而是"Azure AI 平台的客户端框架"。quickstart 默认使用 Azure CLI + Microsoft Foundry，DurableTask 原生集成 Azure 持久化，DevUI 与 Azure 部署管道连通 [ref: facts/maf-001.md §1]。如果你的组织已经运行在 Azure 上，MAF 的默认配置就是优势——不是锁定，而是预设。代价是项目极新（2025-04 创建），核心扩展包（orchestrations、durabletask、devui）仍为 pre-release [ref: facts/maf-001.md §10]。

- **E. 维护已有 AutoGen 项目，评估迁移路径** → **MAF（微软官方推荐）**

  AutoGen 已于 2026-04-06 进入维护模式，不再接收新功能 [ref: facts/autogen-001.md §1]。微软官方 README 已将新用户 redirect 至 MAF，并提供了迁移指南。从 AutoGen 迁移到 MAF 不是"换框架"，而是"升级到产品级重构版"——概念继承（Magentic Builder、GroupChat、MCP）+ 能力升级（图工作流、持久化、中间件系统）[ref: facts/maf-001.md §4]。

如果第一层选出了两个或以上的候选，进入第二层。

**第二层：你对生态锁定的容忍度是多少？**

- **零容忍——框架必须能在任何云、任何模型提供商上运行，不依赖特定平台的可观测性或托管** → **排除 LangGraph、CrewAI、MAF，只剩 smolagents**

  smolagents 由 Hugging Face 维护，License 为 Apache-2.0，无任何商业平台绑定 [ref: facts/smolagents-001.md §仓库基础状态]。模型支持通过 LiteLLM 覆盖 100+ 提供商，工具可来自任意来源。代价是没有官方提供的企业级 tracing、托管或团队协作方案——这些需要自行搭建或寻找第三方。

- **可接受轻度诱导——开源核心完整，商业平台是可选增强** → **LangGraph 或 CrewAI**

  LangGraph 本身 MIT 许可，LangSmith 是可观测性增强而非功能锁 [ref: facts/langgraph-001.md §生态位与商业闭环]。CrewAI 开源版本功能完整，CrewAI Cloud 是托管选项而非必需 [ref: facts/crewai-001.md §维护活跃度评估]。两者的商业平台都处于"诱导"而非"强制"状态——你可以完全不用，但用了会更方便。

- **已在目标生态中——商业平台集成是加分项** → **MAF（Azure）、LangGraph（LangSmith）、CrewAI（Cloud）**

  如果你的团队已经在使用 Azure AI Search、Azure Functions 或 Microsoft Foundry，MAF 的默认配置节省的不是钱，是集成时间 [ref: facts/maf-001.md §7]。同理，已经在 LangChain 生态中的团队选择 LangGraph 的迁移成本最低，已经在 CrewAI Cloud 上的团队继续使用 CrewAI 最顺畅。

**第三层：你的团队规模和技能栈？**

这一层用于在第二层仍有两候选时做最终排除。

- **小团队（1-3 人），快速迭代，无专职 DevOps** → **smolagents**

  小团队的瓶颈不是框架能力边界，而是认知负担。smolagents 的 API 表面最小，文档最短，部署只需 `pip install` [ref: facts/smolagents-001.md §核心架构声明]。注意：生产环境必须切换到 E2B/Docker/WASM 沙箱，不能依赖默认的 LocalPythonExecutor [ref: facts/smolagents-001.md §沙箱层级]。

- **团队有 .NET/C# 背景，或需要 Python/C# 双语言运行时** → **MAF**

  MAF 的 Python 与 C# 代码量接近 1:1（50% vs 45%），是真正的双语言优先框架 [ref: facts/maf-001.md §3]。AutoGen 虽也支持双语言，但 Python 占 64%、C# 仅 26%，且已维护模式 [ref: facts/autogen-001.md §3]。需要 .NET 集成的团队，MAF 是唯一活跃选项。

- **团队有图论/状态机/分布式系统经验** → **LangGraph**

  LangGraph 的 Pregel 引擎、state channels、checkpointing 等概念对有图论背景的开发者而言是熟悉的抽象 [ref: facts/langgraph-001.md §核心架构声明]。但如果团队没有这类背景，培训成本可能超过框架带来的收益——这正是 Anthropic 警告"简单优于复杂"的适用场景 [ref: methodology/reverse-anthropic-building-effective-agents.md]。

- **团队偏好自然语言描述业务逻辑，而非代码定义流程** → **CrewAI**

  CrewAI 的 `role`/`goal`/`backstory` 三元组让业务人员能直接参与 Agent 设计 [ref: facts/crewai-001.md §核心架构声明]。但需要注意：自然语言角色描述的效果不可验证，不同 LLM 对相同描述的理解差异可能导致不可预期行为——这个风险在 §4.2 已有详细讨论。

---

### §9.2 何时甚至不该用框架

五个框架各有适用场景，但存在一个更前置的问题：**这个任务是否值得引入任何框架？**

Anthropic "Building Effective Agents" 的核心方法论之一是"简单优于复杂"——在任务步骤少于 3 步、无需状态共享、无需人机交互、无需持久化的场景下，任何 Agent 框架都是过度工程 [ref: methodology/reverse-anthropic-building-effective-agents.md]。直接用 OpenAI/Anthropic API 的函数调用能力，写 50 行 Python 脚本，比引入 500+ 文件、多包版本管理的框架更可靠。

具体排除指标：

| 指标 | "不需要框架"阈值 |
|------|----------------|
| 任务步骤数 | ≤ 3 步 |
| 状态共享需求 | 无（每步独立输入输出） |
| 人机交互介入点 | 无 |
| 持久化/容错需求 | 无（失败即重跑） |
| 工具调用数 | ≤ 5 个 |
| 多 Agent 协作 | 无（单 Agent 即可） |

如果你的任务满足以上全部条件，框架带来的不是加速，而是负担：依赖管理、版本升级、概念学习、部署复杂度。smolagents 虽然口号是"极简"，但 1,814 行核心代码 + 517 个 open issues + 3.5 个月无 release 的现实意味着"极简框架"也有维护成本 [ref: facts/smolagents-001.md §仓库基础状态]。

另一个"不该用框架"的信号是：你的团队正在用框架解决"模型能力不足"的问题。如果 LLM 在零框架条件下无法可靠完成任务，增加一个控制流框架不会提升模型本身的推理能力——它只是把失败的路径从"随机"变成了"结构化随机"。先提升 prompt 工程、换用更强的模型、或增加 few-shot 示例，再考虑框架。

> **图 7 插入位置**：三层决策树流程图（见 image-prompts 图 7）。
