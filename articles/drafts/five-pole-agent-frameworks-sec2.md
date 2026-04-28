## §2 定义与边界：从"五选一"到"五维坐标系"（~1,800 字）

### §2.1 "Agent 框架"定义困境的升级

在《smolagents 与 LangGraph：两种 Agent 范式的光谱分析》（本文系列第一篇）中，我们用"控制流显式度"这一单维光谱描述了两个项目的差异 [ref: articles/published/smolagents-vs-langgraph.md]。这个光谱在双极对比中有效，但面对五个项目时，单维度的分辨率不足——CrewAI 和 AutoGen 在控制流上的差异，无法仅用"显式/隐式"二元区分；smolagents 和 LangGraph 在生态策略上的对立，也无法在控制流光谱上找到表达位置。

更深层的问题是："Agent 框架"这个术语本身正在经历概念膨胀。2023 年的技术讨论中，"Agent 框架"几乎专指"一个让 LLM 调用工具的库"。到 2026 年，同一个标签下已经混杂了至少五种不同的技术形态：极简工具调用封装（smolagents Tier 0）、角色驱动的多 Agent 协作平台（CrewAI）、显式状态机图引擎（LangGraph）、Actor 模型消息传递运行时（AutoGen）、分层企业级 Agent 基础设施（MAF）。用同一个词指代五种不同的东西，必然导致讨论失焦。

本文的应对方式不是给出一个更精确的定义（"Agent 框架 = X"），而是承认定义的困境本身，并用多维坐标系绕过它。我们不争论"什么是真正的 Agent 框架"，而是问"你的项目需要哪些能力，每个框架在哪些能力上最强"。这是从本体论（是什么）到实用主义（能做什么）的视角转换。

### §2.2 五维坐标系定义

五个维度的设计遵循两条原则：**每个维度必须可观测**（能从源码、文档或 API 中直接验证），**每个维度必须有明确的左右两端**（形成光谱而非散点）。

| 维度 | 左端 | 右端 | 度量方式 |
|------|------|------|---------|
| **控制流显式度** | 黑盒 ReAct（框架决定每一步） | 白盒状态图（开发者决定每一步） | 开发者需要显式定义的控制流节点比例 |
| **角色语义深度** | 无角色概念 | 角色即第一公民（role/goal/backstory） | 框架 API 中角色相关字段的丰富度与强制度 |
| **生态锁定强度** | 零锁定，可随意替换模型/工具/部署 | 深度绑定单一商业云平台 | 核心功能对第三方商业服务的依赖度 |
| **跨语言支持** | 单语言（Python） | 多语言运行时互操作（官方一等公民） | 官方支持的语言数及运行时集成深度 |
| **生产就绪梯度** | 原型/实验工具 | 企业级部署平台 | 持久化、可观测性、安全沙箱、托管方案完备度 |

**控制流显式度**是最核心的维度，因为它直接回答了"谁决定 Agent 何时做什么"这一根本问题。左端的框架把控制流交给 LLM 的 ReAct loop（smolagents），右端的框架要求开发者显式绘制状态转换图（LangGraph）。中间的框架分布更复杂：CrewAI 把控制流分散在 Process enum、Agent delegation 工具、Flow 框架和 Task 依赖链四个子系统中 [ref: facts/crewai-001.md]；AutoGen 把控制流交给 Team 的调度策略（RoundRobin/Selector/GraphFlow）[ref: facts/autogen-001.md]；MAF 提供分层选项（Tier 0 黑盒 → Builder 半显式 → Workflow 全显式）[ref: facts/maf-001.md]。

**角色语义深度**测量的是框架对"Agent 身份"这一概念的重视程度。smolagents 和 LangGraph 完全不提供角色抽象——前者把 Agent 视为"工具列表 + ReAct loop"，后者把 Agent 视为"状态图中的一个节点函数" [ref: facts/smolagents-001.md] [ref: facts/langgraph-001.md]。CrewAI 将角色语义推到极致：`Agent(role, goal, backstory)` 三元组是构造函数的核心必填项 [ref: facts/crewai-001.md]。AutoGen 和 MAF 处于中间：AutoGen 提供 `name`/`description` [ref: facts/autogen-001.md]，MAF 提供 `name`/`instructions` [ref: facts/maf-001.md]。

**生态锁定强度**测量的是框架对特定商业平台的依赖程度。这个维度与框架发起方的商业模式直接相关。smolagents 由 Hugging Face（非营利技术社区）维护，无商业平台绑定 [ref: facts/smolagents-001.md]。LangGraph 由 LangChain 公司维护，完整的可观测性和部署方案锁定在 LangSmith 商业平台 [ref: facts/langgraph-001.md]。CrewAI 由 crewAIInc 维护，企业级功能锁定在 CrewAI Cloud [ref: facts/crewai-001.md]。MAF 由微软官方产品团队维护，默认集成 Microsoft Foundry、Azure Functions、DurableTask 和 Cosmos DB [ref: facts/maf-001.md]。AutoGen 作为研究院项目无商业绑定，但正因如此也缺乏持续投入，已进入维护模式 [ref: facts/autogen-001.md]。

**跨语言支持**衡量的是多语言能力是否为一等公民，而非"社区移植版"。AutoGen 和 MAF 是五极中唯二官方支持 Python/C# 双语言的项目 [ref: facts/autogen-001.md] [ref: facts/maf-001.md]，但两者的语言比例和集成深度不同：AutoGen 的 Python 代码占 64%、C# 占 26% [ref: facts/autogen-001.md]，MAF 的 Python 占 50%、C# 占 45%，更接近均衡 [ref: facts/maf-001.md]。其余三个项目均为纯 Python。

**生产就绪梯度**衡量的是框架内置的企业级能力完备度。LangGraph 提供原生 checkpointing 和 LangGraph Platform 托管方案 [ref: facts/langgraph-001.md]。MAF 提供 DurableTask 持久化、DevUI 开发环境、Hyperlight 安全沙箱和 Azure Functions 托管 [ref: facts/maf-001.md]。CrewAI 提供 State/Checkpoint 内存管理和 Flow 持久化接口 [ref: facts/crewai-001.md]。smolagents 和 AutoGen 在这一维度上最弱：smolagents 无内置持久化或可观测性 [ref: facts/smolagents-001.md]，AutoGen 的 Studio 明确声明"非生产就绪" [ref: facts/autogen-001.md]。

### §2.3 每个维度上的五极定位

将五个项目放入坐标系，得到以下初步定位（具体论证分布在 §3 至 §6）：

**控制流显式度**（从左到右）：smolagents（完全黑盒 ReAct，loop 完全封装在 `agents.py` 内）[ref: facts/smolagents-001.md] → CrewAI（分布式黑盒，控制流分散在 Process、Agent tools、Flow、Task 依赖四个子系统中）[ref: facts/crewai-001.md] → AutoGen（Actor 消息 + Team 调度策略，开发者选模式但不可定制逻辑）[ref: facts/autogen-001.md] → MAF Builder（半显式，五种预设编排模式）[ref: facts/maf-001.md] → LangGraph / MAF Workflow（完全显式状态图，开发者定义每一条边和条件）[ref: facts/langgraph-001.md] [ref: facts/maf-001.md]。

**角色语义深度**（从浅到深）：smolagents = LangGraph（无角色概念，Agent = 工具列表或节点函数）[ref: facts/smolagents-001.md] [ref: facts/langgraph-001.md] → AutoGen（`name`/`description`）[ref: facts/autogen-001.md] → MAF（`name`/`instructions`）[ref: facts/maf-001.md] → CrewAI（`role`/`goal`/`backstory` 三元组，核心必填项）[ref: facts/crewai-001.md]。

**生态锁定强度**（从弱到强）：smolagents（Apache-2.0，零商业绑定，LiteLLM 覆盖 100+ 提供商）[ref: facts/smolagents-001.md] → LangGraph（MIT，开源核心完整，可观测性/部署锁定 LangSmith）[ref: facts/langgraph-001.md] → CrewAI（MIT，开源功能完整，企业级能力锁定 Cloud）[ref: facts/crewai-001.md] → MAF（MIT，深度 Azure 绑定，默认 Microsoft Foundry）[ref: facts/maf-001.md]。AutoGen 无商业锁定但已维护模式 [ref: facts/autogen-001.md]。

**跨语言支持**（从单到多）：CrewAI = LangGraph = smolagents（纯 Python）[ref: facts/crewai-001.md] [ref: facts/langgraph-001.md] [ref: facts/smolagents-001.md] → AutoGen（Python 64% / C# 26%，protobuf 跨语言）[ref: facts/autogen-001.md] → MAF（Python 50% / C# 45%，双语言独立发版）[ref: facts/maf-001.md]。

**生产就绪梯度**（从低到高）：smolagents（无持久化/可观测性，原型级）[ref: facts/smolagents-001.md] → AutoGen（Studio"非生产就绪"，无内置持久化）[ref: facts/autogen-001.md] → CrewAI（State/Checkpoint + Flow 持久化，企业级扩展中）[ref: facts/crewai-001.md] → LangGraph（原生 checkpointing + Platform 托管，平台级）[ref: facts/langgraph-001.md] → MAF（DurableTask + DevUI + Hyperlight + 多协议，企业级覆盖最广）[ref: facts/maf-001.md]。

这些定位不是静态的评分，而是动态的能力边界。一个框架可以在某个维度上很强，在另一个维度上很弱——这正是"五选一"思维失效的原因。本文后续章节将逐维展开论证，并在 §7 中汇总为一张 16 维对比表，在 §9 中提炼为可直接使用的决策树。

> **图 0 插入位置**：五维坐标系示意图，五个项目在五条平行轴上的定位。横轴为五个维度，纵轴为每个维度上的位置。详见 `image-prompts/five-pole-agent-frameworks.md` 图 0。
