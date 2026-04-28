## §0 摘要（~1,200 字）

2026 年的开源 Agent 框架市场已经度过了"概念验证"阶段，进入了"选型决策"阶段。CrewAI、LangGraph、smolagents、AutoGen 和 Microsoft Agent Framework（MAF）五个项目占据了中文技术社区讨论的高地，但一个根本性的误导贯穿了绝大多数选型文章：用 GitHub star 数回答"该选谁"。这个误导的破坏力在于，它把复杂的架构抉择压缩成了一个单维排序题，而忽略了五个项目在设计哲学、控制流范式、生态策略和生产就绪度上的根本差异。

截至 2026 年 4 月，五个项目的 star 数排名是 AutoGen 57.5K > CrewAI 50.1K > LangGraph 30.6K > smolagents 26.9K > MAF 9.9K [ref: facts/autogen-001.md] [ref: facts/crewai-001.md] [ref: facts/langgraph-001.md] [ref: facts/smolagents-001.md] [ref: facts/maf-001.md]。但这个排名与"你的项目该选谁"完全无关。AutoGen 拥有最高 star 数，却已在 2026 年 4 月 6 日官宣维护模式，微软明确推荐新用户迁移至 MAF [ref: facts/autogen-001.md]。MAF 仅 9.9K star，却是微软官方产品团队主推的活跃框架，发版频率高达每 2-3 天一次 [ref: facts/maf-001.md]。Star 数测量的是传播热度，不是技术适合度；是 bookmark 按钮的点击量，不是生产负载的承载量。

本文基于源码级事实和官方文档，构建了一个可操作的五维坐标系决策框架——控制流显式度、角色语义深度、生态锁定强度、跨语言支持和生产就绪梯度。每个框架在这五个维度上占据不同的位置，真实的选型逻辑不是"五选一排序"，而是"在五维空间中找到与你项目需求匹配的坐标点"。在逐维拆解的过程中，三个反直觉的发现浮出水面。

**第一，CrewAI 的 `Process` 抽象仅 11 行代码（2 个 enum 值），真正的编排复杂度分散在 15 子系统之中。** `Process` 层过薄——`sequential` 和 `hierarchical` 两个 enum 值没有状态转换图、没有条件分支语法、没有循环或并发原语 [ref: facts/crewai-001.md]。真正的控制流隐藏在 Agent delegation 工具（`DelegateWorkTool`/`AskQuestionTool`）、Flow 框架（3,572 行的 `@start`/`@listen`/`@router` 事件驱动系统）和 Task `context` 依赖链三个互不统属的子系统中 [ref: facts/crewai-001.md]。这与 README 中 "lean, lightning-fast" 的自我定位之间存在真实的张力——519 个核心文件的事实与极简口号之间的落差，揭示了" lean 框架"在功能压力下的结构性膨胀困境。当用户需要超越简单顺序执行时，他们被迫同时掌握四个独立的心理模型：Process enum、Agent 工具、Flow 装饰器和 Task 依赖链。

**第二，MAF 不是 AutoGen 的改名，而是一次从"研究院原型"到"产品团队重构"的断裂式接力。** 中文社区几乎一致将 MAF 描述为"AutoGen 的继任者"或"新版 AutoGen"，但源码级事实不支持这一叙事。MAF 的 GitHub 仓库 `microsoft/agent-framework` 于 2025 年 4 月 28 日独立创建，与 `microsoft/autogen` 没有共享提交历史 [ref: facts/maf-001.md]。两者的包结构完全不同：AutoGen 采用严格的三层架构（Core/Chat/Ext），MAF 改用扁平的 Tier 0/1/2 + namespace packages [ref: facts/autogen-001.md] [ref: facts/maf-001.md]。编程语言比例从 AutoGen 的 Python 64%/C# 26% 变为 MAF 的 Python 50%/C# 45%，接近均衡 [ref: facts/autogen-001.md] [ref: facts/maf-001.md]。MAF 引入了 AutoGen 完全不具备的能力：原生 Graph-based 工作流（含 checkpointing 和 time-travel）、DurableTask 持久化、多协议支持（MCP + A2A + AG-UI）、原生 Middleware 系统 [ref: facts/maf-001.md]。本文用"继承/断裂矩阵"方法论系统梳理了 5 处概念继承和 8 处工程断裂，为中文社区提供纠正"MAF = AutoGen 改名"误读的源码级证据。

**第三，"极简框架"的设计张力是五个项目共同面临的结构性困境，而非某个项目的个别问题。** smolagents 的 README 声称核心逻辑 "fits in ~1,000 lines of code"，但 `agents.py` 实际为 1,814 行 [ref: facts/smolagents-001.md]。LangGraph 的仓库体积达 518 MB，与 smolagents 的 7.3 MB 形成两个数量级的差距 [ref: facts/langgraph-001.md]。CrewAI 的核心文件数达 519 个，子系统数超过 15 个 [ref: facts/crewai-001.md]。五个项目都在某处声称"简单"，但代码量、子系统数和概念层级都在持续增长。这个困境的深层原因在于：Agent 框架的边界本身正在模糊化——它们从"让 LLM 调用工具的库"逐渐扩张为工作流引擎、可观测性平台和部署工具的混合体。当框架承担的责任超出原始边界时，"极简"口号与功能现实之间的张力就不可避免了。

对于需要在 2026 年做出 Agent 框架选型决策的工程师和技术负责人，本文提供的不止是对比表格，而是一套可以复用到其他技术选型场景的五维分析框架，以及一个可以直接用于技术评审会议的"何时用/何时不用"决策树。

---

## §1 开头钩子：Star 数排名是一个陷阱（~1,500 字）

### §1.1 一个被数字误导的问题

打开任意一个中文技术社区中关于 Agent 框架的讨论帖，排在前三楼的回复大概率是这样的格式：

> "AutoGen 57K star，是不是最稳的？"
> "CrewAI 50K star，为什么比 LangGraph 高？"
> "MAF 才 10K star，是不是还没成熟？"

这种讨论方式预设了一个前提：GitHub star 数是框架成熟度的 proxy，而成熟度是适合度的 proxy。两个 proxy 的传递链看似合理，却在每一步都引入了系统性偏差。

Star 数测量的不是"这个框架在生产环境中解决了多少问题"，而是"多少 GitHub 用户点击了 bookmark 按钮"。Bookmark 的触发因素包括：README 的吸引力、社交媒体的传播热度、概念标签的共鸣度、以及框架名称的搜索引擎友好度——这些因素中，没有一项与"你的特定项目需求"直接相关。

更具体的反直觉事实来自两个极端案例。AutoGen 以 57,512 个 star 位居五极之首 [ref: facts/autogen-001.md]，但它在 2026 年 4 月 6 日已进入维护模式——不再接收新功能，仅由社区维护安全修复 [ref: facts/autogen-001.md]。微软在 AutoGen 的 README 顶部放置了明确的迁移建议：新用户应直接使用 Microsoft Agent Framework。这意味着一个只看 star 数选型的团队，会在项目启动时选择一份官方不再投入资源的代码基。

另一个极端是 MAF。9,885 个 star 在五极中垫底 [ref: facts/maf-001.md]，但它的发版频率是五极中最高的——Python 和 .NET 双语言几乎每 2-3 天各发布一个 patch 或 minor 版本 [ref: facts/maf-001.md]。MAF 的 star 数低不是因为它不受重视，而是因为它创建时间晚（2025 年 4 月，距本文写作刚满一年）[ref: facts/maf-001.md]，尚未积累足够的传播时间。用 star 数判断 MAF 的成熟度，相当于用粉丝数判断一位刚出道一年的歌手的实力——指标与目标完全错配。

### §1.2 两个被忽略的非线性关系

即便我们接受"star 数有参考价值"这一前提，简单的数字对比仍然忽略了两个关键的非线性关系。

**Star 数与时间的关系不是线性的。** CrewAI 创建于 2023 年 10 月，LangGraph 创建于 2023 年 8 月，两者相差仅两个月 [ref: facts/crewai-001.md] [ref: facts/langgraph-001.md]。但截至 2026 年 4 月，CrewAI 的 star 数（50.1K）比 LangGraph（30.6K）高出 64%。这个差距不能用"早两个月积累"来解释——两个月的时间差在 2.5 年的项目周期中仅占 3%。更合理的解释是：CrewAI 的"角色驱动 API"（`role`/`goal`/`backstory` 三元组）具有更高的概念传播性。一个非技术背景的产品经理也能理解"给 Agent 定义角色"的含义，但理解"Pregel 状态图引擎"需要图论和分布式系统的知识门槛。CrewAI 的 star 优势反映的是"概念易传播性"，而非"技术优越性"。

**Star 数与代码量的关系更不是线性的。** smolagents 创建于 2024 年 12 月，历史仅 5 个月，但已达到 26.9K star [ref: facts/smolagents-001.md]。这是五极中 star/时间比最高的项目——按历史长度年化计算，smolagents 的 star 增速超过所有前辈。但 smolagents 的核心代码仅 1,814 行（README 声称 "~1,000 行"）[ref: facts/smolagents-001.md]。高 star/代码量比意味着"概念共鸣度极高"，但不意味着"生产依赖度高"。一个框架可以被大量开发者 bookmark 用于学习、实验和快速原型，却很少被用于承载核心生产负载。smolagents 的 517 个 open issues 中，相当比例集中在"缺少生产级功能"（tracing、持久化、部署方案）上 [ref: facts/smolagents-001.md]，这正是高 star/低代码量比所带来的结构性后果。

这两个非线性关系共同指向一个结论：**star 数排名是一张关于"传播热度"的快照，而不是一张关于"技术适合度"的地图。** 如果选型决策基于热度快照，结果必然是错配——就像根据 Twitter  trending 选择数据库一样荒谬。

### §1.3 本文的替代方案：五维坐标系

既然 star 数排名是一个陷阱，工程师需要什么样的替代工具？

本文的回答是：一个五维坐标系。不是"哪个框架最好"的单维排序，而是"每个框架在哪个维度上最强、在哪个维度上最弱"的多维定位。

五个维度分别是：

- **控制流显式度**：谁决定 Agent 何时做什么——框架全权代劳（黑盒），还是开发者逐行指定（白盒状态图）？
- **角色语义深度**：框架是否为 Agent 提供内置的角色身份概念——从无角色，到 role/goal/backstory 三元组？
- **生态锁定强度**：框架的核心功能在多大程度上依赖特定厂商的商业平台——从完全中立，到深度绑定 Azure？
- **跨语言支持**：框架是否提供官方多语言运行时互操作——从纯 Python，到 Python/C# 双语言一等公民？
- **生产就绪梯度**：框架是否内置企业级能力（持久化、可观测性、安全沙箱、托管方案）——从原型工具，到部署平台？

每个框架在这五个维度上占据不同的位置。CrewAI 在"角色语义深度"上领先，但在"控制流显式度"上分散。LangGraph 在"控制流显式度"上最强，但无角色概念。smolagents 在"生态锁定强度"上最自由，但"生产就绪梯度"最低。MAF 是唯一横跨多个层级的框架，但"生态锁定强度"最高。AutoGen 作为历史参照，揭示了"高 star 数"与"持续维护"之间的断裂。

接下来的章节将逐一解剖这五个维度，并在最后一节提供一个可直接用于技术评审会议的决策树。

---

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
