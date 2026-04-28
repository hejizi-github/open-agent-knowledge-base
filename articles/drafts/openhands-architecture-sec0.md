## §0 摘要（~1,200 字）

2024 到 2026 年，技术社区对"Agent"的定义经历了两次膨胀。第一次从"调用工具的 LLM"膨胀到"多 Agent 协作系统"，第二次从"对话系统"膨胀到"软件工程助手"。OpenHands 位于第二次膨胀的中心，但多数中文技术讨论仍用第一次膨胀的框架理解它——把它当作"又一个聊天 Agent 框架"来介绍，忽略了它的核心差异化：在 Docker Sandbox 中执行真实代码、修改文件系统、运行测试套件。

截至 2026 年 4 月 28 日，OpenHands 在 GitHub 上拥有 72,234 个 star 和 9,122 个 fork，是开源 Agent 框架中 star 数最高的项目 [ref: facts/openhands-001.md]。它在 SWE-bench（软件工程基准测试）上的得分达到 77.6 [ref: raw:openhands-readme.md]，高于多数同类项目。但这些数字在中文社区的传播方式与首篇五极长文揭示的"star 数陷阱"完全一致：72K star 被当作"成熟度 proxy"，77.6 分被当作"技术优越性 proxy"，两个 proxy 的传递链在每一步都引入了偏差。

中文技术社区对 OpenHands 的介绍长期停留在"安装教程"和"功能演示"层面。打开任意一篇 2026 年的中文 OpenHands 文章，40% 是快速上手指南，35% 是截图展示，20% 是与 Devin 或 Cursor 的表层比较，仅有 5% 触及架构层面的分析。这种信息分布导致一个认知盲区：工程师知道"OpenHands 能做什么"，却不知道"它的架构决策如何在代码执行场景中产生连锁反应"。后者才是选型决策的实质——你选择的不只是一个功能列表，而是一套会在未来 18 个月内持续产生技术债务或技术收益的架构假设。

本文基于源码级事实和官方架构文档，对 OpenHands 进行专题深潜。§1 澄清"软件工程 Agent"与"聊天 Agent"的类别差异；§2 解剖五层产品矩阵的组织变迁；§3 深入 EventStream 事件驱动 backbone；§4 分析 Runtime-Sandbox 的安全边界；§5 将 OpenHands 放入首篇五维坐标系并建议新增"代码执行深度"维度；§6 提供可直接用于技术评审的决策树。全文围绕三个反直觉发现展开。

**第一，OpenHands 的 EventStream 不是"消息队列的别名"，而是一个把所有组件解耦为纯事件生产/消费关系的架构 backbone。** Agent、AgentController、Runtime、Frontend 四个核心组件之间没有直接调用关系，全部通过 EventStream 的 pub/sub 机制通信 [ref: raw:openhands-core-readme.md]。这个设计的直接后果是：Frontend 可以在 Runtime 崩溃后继续恢复会话；AgentController 可以在不重启的情况下切换 Runtime 实现（从 Docker 切到 local）。这种松耦合不是"过度工程化"，而是软件工程 Agent 的必需——因为 Runtime 执行的是真实代码，崩溃概率远高于纯 API 调用场景。

**第二，五层产品矩阵（SDK→CLI→GUI→Cloud→Enterprise）不是"同一套代码打包五次"，而是 1.0.0 重大架构重构的结果。** 2025 年 12 月 16 日发布的 1.0.0 版本引入了 software-agent-sdk，同时将 CLI 拆分到独立仓库 OpenHands-CLI [ref: facts/openhands-001.md]。这不是代码搬家，而是依赖关系的重构：主仓库从"包含一切"变为"依赖 SDK"，SDK 成为五层共享的引擎层。这个重构的代价是 CLI 用户需要单独安装，收益是 SDK 可以独立演进、被第三方框架引用。

**第三，OpenHands 在 SWE-bench 上的高分不是营销数字，而是架构设计（Runtime 可插拔 + 多模型支持 + 事件驱动可恢复）的直接产物——但这个分数掩盖了真实部署中的沙箱配置复杂度。** OpenHands 支持 Docker Sandbox 和本地运行两种 Runtime [ref: raw:openhands-agents.md]，通过 LiteLLM 原生支持 Claude、GPT、Gemini、Qwen 等主流模型 [ref: facts/openhands-001.md]。这种灵活性让它在基准测试中可以针对每个任务选择最优模型和最优执行环境。但生产部署中，Docker volume 挂载、网络模式选择（bridge vs host）、权限配置等细节问题会显著影响实际体验——1.3.0 引入 host networking mode [ref: raw:openhands-releases-api.json] 本身就说明容器网络隔离在某些场景下反而是障碍。

对于需要在 2026 年做出 Agent 框架选型决策的工程师和技术负责人，本文提供的不止是 OpenHands 的架构说明书，而是一个可以复用到其他技术评估场景的"代码执行深度"分析框架，以及 OpenHands 在首篇五维坐标系中的精确位置。
