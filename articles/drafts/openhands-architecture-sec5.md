## §5 与五极的对比：OpenHands 在坐标系中的位置（~1,500 字）

§3 和 §4 分别从控制流和执行安全两个维度解剖了 OpenHands 的内部架构。但要回答"OpenHands 在 Agent 框架光谱中处于什么位置"这个问题，需要一把外部尺子——首篇五极长文建立的坐标系 [ref: articles/published/five-pole-agent-frameworks.md]。这把尺子有五个维度：控制流显式度、编排粒度、持久化、人机交互、生态锁定。将 OpenHands 放入这把尺子，会发现它在某些维度上填补了五极图谱中的空白。

### §5.1 控制流显式度：中间偏左，但认知模型更统一

首篇坐标系的第一个维度是"控制流显式度"——开发者能在多大程度上精确控制 Agent 的每一步行为 [ref: articles/published/five-pole-agent-frameworks.md]。在这个维度上，六项目的排列形成了一个连续光谱。

最左端是 smolagents。它的 CodeAgent 将 ReAct 循环封装在 agents.py 内部 [ref: wiki/facts/smolagents-001.md]，开发者只能提供工具列表和初始提示词，无法干预中间过程。LLM 决定每一步调用哪个工具、传递什么参数——控制流是黑盒的。最右端是 LangGraph。它的 Pregel 引擎要求开发者用 nodes 和 edges 显式定义状态转换图 [ref: wiki/facts/langgraph-001.md]，每一步的输入来源、输出去向、条件分支都必须用代码描述——控制流是白盒的。

OpenHands 位于这个光谱的中间偏左位置。AgentController 驱动主循环（显式），但 LLM 决定每一步的 Action 内容（隐式）。开发者可以通过 `.agents/` 目录的配置文件调整 Agent 的行为 [ref: wiki/facts/openhands-001.md]，但无法像 LangGraph 那样精确控制每一步的状态转换。

这个"中间位置"在五极首篇中被描述为一种"妥协"，但在软件工程场景下，它更接近一种**最优解而非次优解**。完全显式的控制流需要开发者手动定义所有可能的代码操作——文件编辑的每一种模式、命令执行的每一种参数组合、错误处理的每一种分支。对于一个真实的代码库，这种显式定义的量级是不现实的。完全隐式的控制流则意味着 Agent 可以执行任何命令而开发者无法预判——在"真实代码执行"的场景下，这等同于把生产环境的 root 权限交给一个不可解释的 LLM。

OpenHands 的"半显式"设计在这两个极端之间找到了一个特定的平衡点：AgentController 保证循环结构的可预测性（每一步都经过 Action → Observation → State Update 的固定模式），但 Action 的具体内容由 LLM 根据当前 State 动态决定。这种平衡在软件工程场景中比纯聊天场景更有价值——因为软件工程 Agent 的操作后果（修改文件、运行测试）具有不可逆性，固定循环结构提供了一种"护栏"，而 LLM 的动态决策保留了处理复杂代码库所需的灵活性。

CrewAI 也处于光谱的中间区域，但它的控制流分散在四个子系统中 [ref: wiki/facts/crewai-001.md]：Agent 的 ReAct loop、Task 的依赖链、Flow 的事件路由、Process 的顺序/层级策略。这种分散使 CrewAI 的中间位置呈现出"碎片化"特征——开发者需要在多个抽象层级之间切换心智模型。OpenHands 的控制流则集中在 AgentController + EventStream 中，认知模型更统一。

AutoGen 的 Actor 模型使控制流显式度取决于开发者的设计选择 [ref: wiki/facts/autogen-001.md]。在 RoundRobinGroupChat 模式下，控制流是隐式的（Agent 轮流发言）；在 GraphFlow 模式下，控制流是显式的（开发者定义 DAG）。MAF 继承了这种分层思路，从 Tier 0（黑盒 Agent）到 Workflow（白盒图编排）提供了显式度的分层选项 [ref: wiki/facts/maf-001.md]。OpenHands 不提供这种分层——它的"半显式"是单一设计，不是选项菜单。这个差异的架构含义是：OpenHands 为自己选择了一个特定的目标场景（软件工程 Agent），并围绕这个场景优化了控制流的显式度；MAF 和 AutoGen 则试图覆盖更广泛的场景，代价是开发者需要自行选择正确的抽象层级。

### §5.2 生产就绪梯度：五层完整，但各层有边界

首篇坐标系没有直接测量"产品矩阵完整性"，但这个维度对工程选型至关重要。OpenHands 在五层产品矩阵上的覆盖度在六项目中是独一无二的 [ref: wiki/facts/openhands-001.md]。

| 项目 | SDK | CLI | GUI | Cloud | Enterprise |
|------|-----|-----|-----|-------|------------|
| OpenHands | 有（独立仓库） | 有（独立仓库） | 有（本地 Docker） | 有（SaaS） | 有（K8s 自托管） |
| smolagents | 有 | 无 | 无 | 无 | 无 |
| LangGraph | 有 | 无 | 无（Studio 属 LangSmith） | 无（LangGraph Platform） | 无 |
| CrewAI | 有 | 有（TUI） | 无 | 有（Cloud） | 无 |
| AutoGen | 有 | 无 | 有（Studio，非生产就绪） | 无 | 无 |
| MAF | 有 | 无 | 有（DevUI） | 无 | 无 |

这个对比表揭示了一个反直觉的结论：**产品矩阵的"完整性"不等于"每个层级都最优"。** OpenHands 的 Cloud 层免费试用使用 Minimax 模型 [ref: wiki/facts/openhands-001.md]，这对需要 Claude/GPT 质量的场景是实质性限制。

Enterprise 层的 source-available License 要求购买商业许可才能运行超过一个月 [ref: wiki/facts/openhands-001.md]，这比 MIT 核心代码更严格。

CLI 在 1.0.0 后拆分为独立仓库 [ref: wiki/facts/openhands-001.md]，意味着 CLI 用户需要额外安装和版本对齐。

LangGraph 的商业闭环是 LangSmith 平台 [ref: wiki/facts/langgraph-001.md]，而非开源框架本身提供 Cloud/Enterprise 层。CrewAI 有 Cloud 产品 app.crewai.com [ref: wiki/facts/crewai-001.md]，但 Enterprise 自托管方案的成熟度不及 OpenHands。AutoGen 的 Studio 被官方明确声明"非生产就绪" [ref: wiki/facts/autogen-001.md]，且项目已进入维护模式。MAF 虽有 DevUI [ref: wiki/facts/maf-001.md]，但项目创建仅一年，产品矩阵尚未经过充分验证。

对于需要在 2026 年做出部署决策的团队，OpenHands 的五层矩阵提供了一条清晰的渐进路径：个人开发者从 SDK 或 CLI 开始，团队引入 Local GUI 做协作演示，验证后迁移到 Cloud 或 Enterprise。其他框架要么缺少这条路径的某些节点（smolagents 无 GUI/Cloud），要么路径的某些节点不成熟（AutoGen Studio 非生产就绪）。

### §5.3 新增维度：代码执行深度

首篇五维坐标系在评估软件工程 Agent 时存在一个盲区：没有直接测量"框架能在多大程度上安全地执行真实代码"。这个盲区是可以理解的——首篇覆盖的五极项目中，只有 AutoGen 有内置的代码执行能力，其余四个项目的核心定位都不是"代码执行框架"。但 OpenHands 的加入使这个维度变得不可回避。

建议将"代码执行深度"作为第 6 维加入坐标系，测量框架在三个子维度上的表现：

| 框架 | 执行环境隔离 | 文件系统修改 | 测试套件运行 | 综合评级 |
|------|-------------|-------------|-------------|---------|
| OpenHands | Docker Sandbox / local 可选 | 完整支持 | 内置 pytest 集成 | **高** |
| smolagents | E2B / Docker / WASM / local | Python 代码执行 | 需外部配置 | **中** |
| AutoGen | DockerCommandLineCodeExecutor | 完整支持 | 需外部配置 | **中** |
| LangGraph | 无内置 | 无 | 无 | **低** |
| CrewAI | 无内置 | 无 | 无 | **低** |
| MAF | CodeAct + Hyperlight（proposed） | proposed | proposed | **中（潜力）** |

这个维度的存在改变了选型的核心问题。多数技术讨论将框架对比聚焦于"支持多少种 LLM"或"集成多少种工具"——这些问题在 2026 年已经趋同（所有主流框架都通过 LiteLLM 或类似机制支持多模型，都通过 MCP 支持工具扩展）。真正区分框架的是：**当你的 Agent 需要执行 `git clone`、`npm install`、`pytest`、`playwright test` 时，框架提供了什么级别的安全保障和可观测性？**

OpenHands 在这个维度上的高分不是因为它"功能更多"，而是因为它的架构设计（EventStream 可恢复 + Runtime 可插拔 + Sandbox 隔离）使"真实代码执行"成为一个一等公民能力，而非事后添加的功能模块。这个差异的实证来自 SWE-bench：OpenHands 的 77.6 分 [ref: raw:openhands-readme.md] 不是"模型更强"的结果（它支持多种模型，包括与 smolagents 相同的模型），而是"执行环境更可靠"的结果——Agent 可以在隔离环境中反复尝试、回滚、验证，而不会污染宿主系统。

> **图 6 插入位置**：六维坐标系（五维 + 代码执行深度）定位图。三维雷达图或六边形图，六个顶点分别对应控制流显式度、编排粒度、持久化、人机交互、生态锁定、代码执行深度。OpenHands 用蓝色填充，其他五极用灰色轮廓线对比。OpenHands 在"代码执行深度"和"生态锁定"两个维度上显著突出。详见 `image-prompts/openhands-architecture.md` 图 6。
