## §0 摘要（~1,200 字）

2026 年的开源 Agent 框架市场已经度过了"概念验证"阶段，进入了"选型决策"阶段。CrewAI、LangGraph、smolagents、AutoGen 和 Microsoft Agent Framework（MAF）五个项目占据了中文技术社区讨论的高地，但一个根本性的误导贯穿了绝大多数选型文章：用 GitHub star 数回答"该选谁"。这个误导的破坏力在于，它把复杂的架构抉择压缩成了一个单维排序题，而忽略了五个项目在设计哲学、控制流范式、生态策略和生产就绪度上的根本差异。

截至 2026 年 4 月，五个项目的 star 数排名是 AutoGen 57.5K > CrewAI 50.1K > LangGraph 30.6K > smolagents 26.9K > MAF 9.9K [ref: facts/autogen-001.md] [ref: facts/crewai-001.md] [ref: facts/langgraph-001.md] [ref: facts/smolagents-001.md] [ref: facts/maf-001.md]。但这个排名与"你的项目该选谁"完全无关。AutoGen 拥有最高 star 数，却已在 2026 年 4 月 6 日官宣维护模式，微软明确推荐新用户迁移至 MAF [ref: facts/autogen-001.md]。MAF 仅 9.9K star，却是微软官方产品团队主推的活跃框架，发版频率高达每 2-3 天一次 [ref: facts/maf-001.md]。Star 数测量的是传播热度，不是技术适合度；是 bookmark 按钮的点击量，不是生产负载的承载量。

本文基于源码级事实和官方文档，构建了一个可操作的五维坐标系决策框架——控制流显式度、角色语义深度、生态锁定强度、跨语言支持和生产就绪梯度。每个框架在这五个维度上占据不同的位置，真实的选型逻辑不是"五选一排序"，而是"在五维空间中找到与你项目需求匹配的坐标点"。在逐维拆解的过程中，三个反直觉的发现浮出水面。

**第一，CrewAI 的 `Process` 抽象仅 11 行代码（2 个 enum 值），真正的编排复杂度分散在 15 子系统之中。** `Process` 层过薄——`sequential` 和 `hierarchical` 两个 enum 值没有状态转换图、没有条件分支语法、没有循环或并发原语 [ref: facts/crewai-001.md]。真正的控制流隐藏在 Agent delegation 工具（`DelegateWorkTool`/`AskQuestionTool`）、Flow 框架（3,572 行的 `@start`/`@listen`/`@router` 事件驱动系统）和 Task `context` 依赖链三个互不统属的子系统中 [ref: facts/crewai-001.md]。这与 README 中 "lean, lightning-fast" 的自我定位之间存在真实的张力——519 个核心文件的事实与极简口号之间的落差，揭示了" lean 框架"在功能压力下的结构性膨胀困境。当用户需要超越简单顺序执行时，他们被迫同时掌握四个独立的心理模型：Process enum、Agent 工具、Flow 装饰器和 Task 依赖链。

**第二，MAF 不是 AutoGen 的改名，而是一次从"研究院原型"到"产品团队重构"的断裂式接力。** 中文社区几乎一致将 MAF 描述为"AutoGen 的继任者"或"新版 AutoGen"，但源码级事实不支持这一叙事。MAF 的 GitHub 仓库 `microsoft/agent-framework` 于 2025 年 4 月 28 日独立创建，与 `microsoft/autogen` 没有共享提交历史 [ref: facts/maf-001.md]。两者的包结构完全不同：AutoGen 采用严格的三层架构（Core/Chat/Ext），MAF 改用扁平的 Tier 0/1/2 + namespace packages [ref: facts/autogen-001.md] [ref: facts/maf-001.md]。编程语言比例从 AutoGen 的 Python 64%/C# 26% 变为 MAF 的 Python 50%/C# 45%，接近均衡 [ref: facts/autogen-001.md] [ref: facts/maf-001.md]。MAF 引入了 AutoGen 完全不具备的能力：原生 Graph-based 工作流（含 checkpointing 和 time-travel）、DurableTask 持久化、多协议支持（MCP + A2A + AG-UI）、原生 Middleware 系统 [ref: facts/maf-001.md]。本文用"继承/断裂矩阵"方法论系统梳理了 5 处概念继承和 8 处工程断裂，为中文社区提供纠正"MAF = AutoGen 改名"误读的源码级证据。

**第三，"极简框架"的设计张力是五个项目共同面临的结构性困境，而非某个项目的个别问题。** smolagents 的 README 声称核心逻辑 "fits in ~1,000 lines of code"，但 `agents.py` 实际为 1,814 行 [ref: facts/smolagents-001.md]。LangGraph 的仓库体积达 518 MB，与 smolagents 的 7.3 MB 形成两个数量级的差距 [ref: facts/langgraph-001.md]。CrewAI 的核心文件数达 519 个，子系统数超过 15 个 [ref: facts/crewai-001.md]。五个项目都在某处声称"简单"，但代码量、子系统数和概念层级都在持续增长。这个困境的深层原因在于：Agent 框架的边界本身正在模糊化——它们从"让 LLM 调用工具的库"逐渐扩张为工作流引擎、可观测性平台和部署工具的混合体。当框架承担的责任超出原始边界时，"极简"口号与功能现实之间的张力就不可避免了。

对于需要在 2026 年做出 Agent 框架选型决策的工程师和技术负责人，本文提供的不止是对比表格，而是一套可以复用到其他技术选型场景的五维分析框架，以及一个可以直接用于技术评审会议的"何时用/何时不用"决策树。

---
