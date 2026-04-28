## §3 控制流显式光谱：五个项目的控制流设计解剖（~3,500 字）

Agent 框架之间的根本差异不在于"有没有 Agent"，而在于"谁决定 Agent 何时做什么"。这个"谁决定"的问题，构成了控制流显式度的光谱——从"框架全权代劳"到"开发者逐行指定"。五个项目在这条光谱上的分布，比它们的 star 数排名更能揭示选型逻辑。

---

### §3.1 光谱左端：smolagents（黑盒 ReAct）

smolagents 将控制流压缩到了极限。`CodeAgent` 的 ReAct loop——感知（observation）→ 思考（thought）→ 行动（action）→ 执行（execution）——被完整地封装在 `agents.py` 的一个类内部。开发者调用接口时，只能提供三项输入：一个 LLM 客户端、一组工具函数、一段初始任务描述 [ref: facts/smolagents-001.md]。除此之外，loop 的每一步决策——何时停止思考、选择哪个工具、如何解析工具输出——全部由框架内部逻辑决定，开发者既看不见，也干预不了。

这种封装在快速原型阶段是优势。一个典型的 smolagents 调用可以在 10 行代码内完成从定义到执行：

```python
from smolagents import CodeAgent, HfApiModel

agent = CodeAgent(tools=[my_tool], model=HfApiModel())
agent.run("分析这份 CSV 并生成图表")
```

但当 loop 失败时——比如模型生成了语法错误的代码、工具返回了异常格式、或者 loop 陷入了无限循环——调试抓手极其有限。框架提供的唯一观察窗口是 `verbosity` 参数控制的日志级别，开发者只能在 `INFO` 或 `DEBUG` 输出中被动阅读框架的决策痕迹，无法像操作状态机那样在特定步骤插入断点或改写路由逻辑 [ref: facts/smolagents-001.md]。

**适用场景**：单 Agent 任务、模型能力足够强（GPT-4/Claude 级别）、不需要精确控制执行路径的验证型项目。

**不适用场景**：多 Agent 协作（框架本身不原生支持多 Agent 状态共享）、需要人机交互介入点（无内置 interrupt 机制）、执行路径必须可审计或必须符合合规要求（黑盒 loop 无法满足可追溯性）。

---

### §3.2 光谱左中：CrewAI（分布式控制流）

CrewAI 的控制流设计表面上有一个清晰的入口：`Crew` 类的 `process` 参数，可选 `sequential` 或 `hierarchical`。但这个入口的源码只有 11 行——一个包含两个 enum 值的字符串枚举，外加一行被注释掉的 `consensual` [ref: facts/crewai-001.md]。`sequential` 的含义是按 `tasks` 列表顺序执行；`hierarchical` 的含义是引入一个 manager agent 动态分配任务给 worker agents。仅此而已。没有状态转换图，没有条件分支语法，没有循环或并发原语。

真正的编排复杂度被分散到了三个互不统属的子系统中：

**第一处：Agent delegation 工具。** CrewAI 的每个 Agent 可以被赋予 `allow_delegation=True`，此时框架自动为其挂载两个隐藏工具——`DelegateWorkTool`（将任务委托给其他 Agent）和 `AskQuestionTool`（向其他 Agent 提问）。这两个工具由 LLM 在 ReAct loop 内部自主调用，意味着 Agent 之间的协作路由完全由模型决定，而非开发者显式指定 [ref: facts/crewai-001.md]。一个 manager agent 在 `hierarchical` 模式下负责顶层调度，但 worker agents 之间的横向通信仍然是黑盒。

**第二处：Flow 框架。** 这是 CrewAI 在 v1.x 系列引入的重大架构扩展。Flow 提供 `@start`、`@listen`、`@router` 三个装饰器，允许开发者以事件驱动的方式定义工作流节点和边。`flow.py` 的实现长达 3,572 行，支持条件路由（`AND_CONDITION` / `OR_CONDITION`）、状态持久化（`FlowPersistence` 接口）和可视化输出——功能域上与 LangGraph 的图编排直接重叠 [ref: facts/crewai-001.md]。

**第三处：Task `context` 依赖链。** 开发者在定义 Task 时可以通过 `context=[previous_task]` 显式声明前置依赖，框架确保前置任务的输出作为字符串注入后续任务的描述中。这是一种显式的数据流声明，但不是控制流声明——它只保证执行顺序，不定义状态转换条件。

**关键洞察**：CrewAI 没有统一的控制流抽象。Process 层过薄，Agent 层是黑盒 ReAct，Flow 层是独立的事件驱动框架，Task 层是显式依赖链。控制流被"分布式"地散布在四个不同的概念层级中，开发者需要在脑中同时维护四个独立的心理模型才能理解一个 Crew 的完整执行路径。这与 LangGraph 的"一切控制流都是显式图"形成了鲜明反差。

**适用场景**：角色分工明确的多 Agent 协作（研究员→写手→编辑的流水线）、需要事件驱动响应的企业场景（如"当新邮件到达时触发分析 Agent"）。

**不适用场景**：需要统一状态视角的复杂工作流（状态分散在 Agent 工具内部状态、Flow 装饰器上下文和 Task 输出中，难以全局审计）、需要精确控制每一步执行路径的安全敏感场景。

---

### §3.3 光谱中右：AutoGen（Actor 模型消息传递）

AutoGen 在控制流设计上走了另一条中间路线。其 Core API 基于 Actor 模型：每个 Agent 是一个独立的 Actor，拥有私有状态，通过异步消息传递与其他 Actor 通信 [ref: facts/autogen-001.md]。这个设计比 CrewAI 的分布式 ReAct 更结构化——Agent 之间的交互不是通过隐藏工具实现的，而是通过显式的消息类型（`TextMessage`、`ToolCallMessage`、`ToolCallResultMessage` 等）在类型安全的通道中流转。

但控制流的最终决策权仍然不在开发者手中，而在"Team"的调度策略中。AgentChat API 提供了四种预设团队模式 [ref: facts/autogen-001.md]：

- `RoundRobinGroupChat`：轮询发言，最简模式，无智能路由。
- `SelectorGroupChat`：由模型根据对话内容选择下一位发言者，引入了智能路由，但选择逻辑仍是黑盒。
- `GraphFlow`：允许开发者用有向图定义执行顺序，支持并发 fan-out（`List[str]` 返回多 agent 并行执行），是 AutoGen 中最接近显式控制流的模式——但条件边（callable conditions）被文档标注为"不可序列化"的实验性功能。
- `MagenticOneGroupChat`：结构化输出编排，将复杂任务分解为预定义的子任务序列。

在这四种模式中，只有 `GraphFlow` 赋予开发者接近 LangGraph 的显式控制能力，但 `GraphFlow` 的实现深度远不及 LangGraph 的 Pregel 引擎——没有原生 checkpointing、没有 time-travel、没有分布式状态管理。其余三种模式的控制流仍由 Team 内部的调度器决定，开发者只能选模式，不能定制调度逻辑。

AutoGen 的 Actor 模型设计在理论上支持跨语言运行时（Python 与 .NET 通过 protobuf 通信），但这一点在实际项目中的使用率有限。更重要的是，AutoGen 自 2026-04-06 已官宣维护模式，微软明确推荐新用户迁移至 MAF [ref: facts/autogen-001.md]。本节对 AutoGen 的分析主要作为理解 MAF 设计背景的前置对照。

---

### §3.4 光谱右端：LangGraph（显式状态机图）

在《smolagents 与 LangGraph：两种 Agent 范式的光谱分析》（本文第一篇）的 §3 中，我们详细拆解了 LangGraph 的 Pregel 引擎：开发者显式定义 `State`（共享状态模式）、`Node`（状态转换函数）和 `Edge`（条件路由），框架的唯一职责是忠实地执行这张开发者手绘的图。状态机的每一步转换都是白盒——开发者在 `conditional_edge` 中写 `if state["score"] > 0.8: return "accept" else: return "revise"`，这条规则直接出现在代码中，而非隐藏在某个框架内部的调度器里 [ref: articles/published/smolagents-vs-langgraph.md]。

LangGraph 是五个项目中控制流显式度最高的框架。这种显式性的代价是认知税：一个简单的"LLM 调用→工具调用→结果返回"流程，在 LangGraph 中需要定义 State schema、至少两个 node 函数、一条条件边和编译步骤。对于步骤少于 3 的任务，这种 overhead 是真实的——也正是 Anthropic "Building Effective Agents" 所警告的"简单 > 复杂"的直接体现 [ref: methodology/reverse-anthropic-building-effective-agents.md]。

但 LangGraph 的显式控制在复杂场景下成为不可替代的优势：需要人机交互介入（`interrupt` 节点）、需要精确审计每一步决策（状态图本身就是审计日志）、需要分布式执行（LangGraph Platform 支持多 worker 分片状态图）时，白盒控制流是唯一能同时满足"可理解"和"可控制"两个要求的方案。

---

### §3.5 光谱新玩家：MAF（分层控制流）

Microsoft Agent Framework 在控制流设计上采取了"分层显式度"策略，这是它与光谱上其他四个项目的最大区别。MAF 不强迫所有场景使用同一抽象级别，而是提供了三条从隐式到显式的上升通道：

**Tier 0：极简入口。** `from agent_framework import Agent` 提供与 smolagents 类似的极简体验——定义名字、指令、工具列表，即可运行。`ai_function` 装饰器进一步压缩了工具定义成本 [ref: facts/maf-001.md]。这一层的控制流是黑盒的，适合快速验证。

**Tier 1 + Builder：半显式编排。** `agent-framework-orchestrations` 包提供了五种 Builder，按控制流复杂度递增排列 [ref: facts/maf-001.md]：

- `SequentialBuilder`：顺序链，控制流完全隐式。
- `ConcurrentBuilder`：并发 fan-out/fan-in，开发者显式指定哪些步骤并行，但框架处理聚合逻辑。
- `HandoffBuilder`：去中心化路由，每个 Agent 自主决定下一个交接目标——控制流分散在各 Agent 的决策逻辑中，与 CrewAI 的 delegation 工具类似。
- `GroupChatBuilder`：选择器驱动的群聊，继承自 AutoGen 的 `SelectorGroupChat` 概念，由模型选择下一位发言者。
- `MagenticBuilder`：结构化任务分解与编排，继承自 AutoGen 的 `MagenticOneGroupChat` 概念。

这五种 Builder 的控制流显式度从左到右递增，但即使是最显式的 `MagenticBuilder`，开发者仍然是在选择预设模式而非绘制自定义状态图。

**Workflow：全显式状态图。** MAF 的 `Workflow` API 是 Builder 层之上的逃逸舱口。它提供了原生 Graph-based 工作流，包含数据流连接、streaming 输出、checkpointing（中断恢复）、human-in-the-loop（人工审批节点）和 time-travel（回溯到任意检查点重新执行）——功能集合直接对标 LangGraph 的核心能力 [ref: facts/maf-001.md]。与 LangGraph 的区别在于：MAF 的 Workflow 是可选的高级功能，而非唯一抽象；开发者可以从 Tier 0 的黑盒起步，仅在需要时才升级到 Workflow 的显式控制。

**DurableTask：持久化控制流。** 通过 `agent-framework-durabletask` 集成，MAF 将控制流状态持久化到外部存储，支持故障自动恢复和分布式执行 [ref: facts/maf-001.md]。这是 AutoGen 完全不具备的能力，也是 MAF 从"原型框架"迈向"企业平台"的关键基础设施。

**适用场景**：需要分层控制的组织（初级开发者用 Tier 0/Builder，高级开发者用 Workflow）、微软/Azure 生态深度用户（DurableTask、Azure Functions、ASP.NET Core 托管原生集成）、需要渐进式复杂度升级的项目（从简单 Agent 起步，逐步引入图编排和持久化）。

**不适用场景**：项目极新（2025-04 创建，刚满一年），`orchestrations` 和 `durabletask` 包仍为 pre-release，API 存在 breaking changes 风险 [ref: facts/maf-001.md]。对非 Azure 用户而言，默认锁定 Microsoft Foundry 的 quickstart 示例构成了隐性门槛。

---

### §3.6 光谱上的两个分水岭与选型锚点

把五个项目放在同一条"控制流显式度"轴线上，可以看到两个清晰的分水岭。

**第一个分水岭位于 CrewAI 与 AutoGen 之间：从"黑盒协作"到"结构化通信"。** smolagents 和 CrewAI 的共同特征是把控制流交给 LLM 的 ReAct loop 决定——开发者定义输入，模型决定每一步走向。smolagents 是单一 Agent 的黑盒，CrewAI 是多 Agent 的分布式黑盒，但本质相同：控制流隐藏在模型的推理过程中。AutoGen 的 Actor 模型改变了这一范式：Agent 之间的交互通过类型化的消息（`TextMessage`、`ToolCallMessage` 等）在显式通道中流转，控制流不再是"模型想怎么调就怎么调"，而是"调度器按预设策略路由消息"。这条分水岭的决策含义是：如果你的场景需要模型自主探索（如研究、头脑风暴），留在分水岭左侧；如果需要可预测的执行路径（如审批流程、合规检查），必须跨越到右侧。

**第二个分水岭位于 AutoGen 与 LangGraph 之间：从"选模式"到"画状态图"。** AutoGen、MAF Builder 和 CrewAI Flow 的共同特征是提供"预设模式菜单"——开发者从框架提供的几种编排模式中选择一种，不能自定义调度逻辑。LangGraph 和 MAF Workflow 则把控制流的定义权完全交给开发者：每一个状态转换条件都是代码中的 `if/else`，每一条边都是显式声明。这条分水岭的决策含义是：如果你的编排逻辑可以用"顺序/并发/选择器"三种模式覆盖，预设菜单足够；如果需要自定义分支条件（如"当置信度低于 0.7 时触发人工审核"），必须采用显式状态图。

MAF 的独特之处在于同时横跨两条分水岭：Tier 0/Builder 位于第一条分水岭的右侧、第二条分水岭的左侧；Workflow 则跨越到第二条分水岭的右侧。这种"分层显式度"设计使 MAF 成为光谱上覆盖范围最广的框架，但也带来了认知成本——团队需要为不同抽象层级建立不同的心智模型。

> **图 1 插入位置**：五项目在"控制流显式度"光谱上的定位图。左端 smolagents（完全黑盒 ReAct），左中 CrewAI（分布式：Process+AgentTools+Flow+Task），中右 AutoGen（Actor 消息+Team 策略），右端 LangGraph（显式状态图），分层 MAF（Tier 0→Builder→Workflow 的上升通道）。详见 `image-prompts/five-pole-agent-frameworks.md` 图 1。
