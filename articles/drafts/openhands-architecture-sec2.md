## §2 OpenHands 全景：从 OpenDevin 到五层产品矩阵（~1,800 字）

### §2.1 改名背后的组织变迁

OpenHands 原名 OpenDevin [ref: facts/openhands-001.md]。这个命名直接指向 2024 年初引发技术社区震动的闭源产品 Devin——一个由 Cognition AI 推出的"AI 软件工程师"演示视频，展示了 AI 自主完成端到端软件开发任务的能力。OpenDevin 作为开源社区的回应，在 2024 年 3 月 13 日创建 [ref: raw:openhands-repo-api.json]，短短数月内积累了大量关注。

但"OpenDevin"这个名称携带了一个结构性问题：它永远将自己定位在"Devin 的复刻/开源替代品"的角色中。无论 OpenDevin 后来发展出什么独特能力，名称都在暗示"我们在追赶 Devin"。2025 年的改名决策——从 OpenDevin 到 OpenHands——不是品牌包装的微调，而是项目身份的根本重定义：从"某个闭源产品的开源版"转向"独立的软件工程 Agent 平台"。

这个重定义在 1.0.0 版本（2025 年 12 月 16 日）中达到高潮 [ref: facts/openhands-001.md]。software-agent-sdk 的引入标志着架构从"单体应用"向"可组合平台"的跃迁。SDK 被提取为独立仓库 [ref: url:https://github.com/OpenHands/software-agent-sdk]，有自己的版本发布节奏（截至 2026 年 4 月已有 678 stars）。CLI 被拆分到 OpenHands-CLI 独立仓库 [ref: raw:openhands-readme.md]。主仓库从"包含一切"变为"聚焦 GUI + Server + Cloud"，通过依赖 SDK 获得核心能力。

这个重构的组织意义大于技术意义。单体架构下，OpenHands 团队需要同时维护 SDK API、CLI 交互逻辑、GUI 前端、Cloud 基础设施和 Enterprise 功能——五个层级的发布节奏互相牵制，一个层的紧急修复可能被迫等待另一个层的版本窗口。拆分后，SDK 可以独立演进（面向框架开发者），CLI 可以独立迭代（面向终端用户），主仓库专注于 GUI 和 Cloud 的体验优化。这种组织解耦是项目从"社区实验"走向"产品平台"的标志。

### §2.2 五层产品矩阵解剖

OpenHands 的五层产品矩阵不是营销话术，而是五个独立可部署、独立演进的技术产物 [ref: raw:openhands-readme.md]：

| 层级 | 形态 | 技术栈 | 部署模式 | 目标用户 |
|------|------|--------|----------|----------|
| L1 SDK | software-agent-sdk | Python 库 | `pip install` | 框架开发者、需要集成 Agent 能力的第三方项目 |
| L2 CLI | OpenHands-CLI | Python 终端应用 | 独立安装 | 个人开发者，习惯终端交互 |
| L3 GUI | Local GUI | React + FastAPI | 本地 Docker | 团队开发者，需要可视化界面 |
| L4 Cloud | app.all-hands.dev | SaaS 托管 | 浏览器访问 | 中小团队，零运维部署 |
| L5 Enterprise | 自托管 Kubernetes | Source-available | VPC 内部署 | 大企业，数据安全合规需求 |

每层的技术选择都值得单独分析。L1 SDK 作为引擎层，采用纯 Python 库形态，不绑定任何 Web 框架或前端技术——这保证了它可以被嵌入到任何 Python 项目中，无论对方使用 Django、Flask 还是 FastAPI。L2 CLI 的体验对标 Claude Code 和 Codex [ref: raw:openhands-readme.md]，这意味着交互设计遵循"对话式编程"范式：用户在终端中与 Agent 对话，Agent 直接修改本地文件系统。L3 GUI 的前端使用 React + TanStack Query [ref: facts/openhands-001.md]，数据获取层标准化，降低了前后端协作的摩擦。

L4 Cloud 的商业模式值得注意：免费试用使用 Minimax 模型 [ref: raw:openhands-readme.md]，这是一个成本控制决策——Minimax 是中国的大模型厂商，API 定价低于 Claude 和 GPT。对于"试用"场景，Minimax 的质量足够；对于"生产"场景，用户需要连接自己的模型 API key。这个分层策略（免费层用低成本模型，生产层用用户自选模型）在 SaaS 产品中常见，但 OpenHands 的开源属性让这种分层更透明。

L5 Enterprise 的 License 边界是 OpenHands 产品矩阵中最复杂的一点。核心代码（`openhands/`、`agent-server` Docker 镜像）以 MIT License 发布 [ref: raw:openhands-readme.md]，但 `enterprise/` 目录采用 source-available 许可：代码可见，但运行超过一个月需要购买商业许可。这个混合许可策略的直接后果是：企业用户可以在代码层面审计 Enterprise 功能的安全性，但不能免费长期使用。与五极中的 CrewAI Cloud（完全闭源商业平台）和 LangGraph Platform（部分开源 + 商业托管）相比，OpenHands 的许可分层更细，但也更复杂。

### §2.3 版本演进与发布节奏

从 0.62.0（2025 年 11 月 11 日）到 1.6.0（2026 年 3 月 30 日），OpenHands 在 4 个半月内发布了 7 个小版本 [ref: facts/openhands-001.md]。发布节奏如下：

| 版本 | 日期 | 关键变化 |
|------|------|----------|
| 0.62.0 | 2025-11-11 | 末版 0.x，为 1.0.0 做准备 |
| 1.0.0 | 2025-12-16 | software-agent-sdk 引入；CLI 拆分；Task Tracker 界面 [ref: raw:openhands-releases-api.json] |
| 1.1.0 | 2025-12-30 | OAuth 2.0 Device Flow；Forgejo 集成 [ref: raw:openhands-releases-api.json] |
| 1.2.0 | 2026-01-15 | 状态指示器；condenser max_size 120→240 [ref: raw:openhands-releases-api.json] |
| 1.3.0 | 2026-02-02 | CORS 支持；host networking mode [ref: raw:openhands-releases-api.json] |
| 1.4.0 | 2026-02-17 | MiniMax-M2.5 模型支持 [ref: raw:openhands-releases-api.json] |
| 1.5.0 | 2026-03-11 | Planning Agent；Bitbucket Datacenter；多模型支持（Claude Opus 4.6 等）[ref: raw:openhands-releases-api.json] |
| 1.6.0 | 2026-03-30 | Hooks 支持；/clear 命令；CVE 修复 [ref: raw:openhands-releases-api.json] |

这个发布节奏（约每 2-3 周一个小版本）比五极中的 CrewAI 更激进。CrewAI 在同期发布了 1.10.x 到 1.14.x 系列，但版本间隔约为 3-4 周 [ref: facts/crewai-001.md]。LangGraph 的发布频率更高（几乎每周），但 patch 版本居多，minor 版本间隔约为 1-2 个月 [ref: facts/langgraph-001.md]。

高频率发版的代价是什么？从 release notes 的内容分布观察，1.x 系列的核心变化集中在三类：

**第一类，模型支持扩展**（1.4.0 MiniMax-M2.5、1.5.0 Claude Opus 4.6）。这得益于 LiteLLM 的统一代理层 [ref: facts/openhands-001.md]——新增模型支持不需要修改 OpenHands 的核心逻辑，只需在 LiteLLM 的配置层添加模型参数。这是架构设计的前瞻性收益。

**第二类，平台集成**（1.1.0 Forgejo、1.5.0 Bitbucket Datacenter）。这反映了 OpenHands 的企业用户需要在不同 Git 托管平台上运行 Agent。GitHub 是预设选项，但企业客户使用 GitLab、Bitbucket 或自托管 Forgejo 的比例不容忽视。

**第三类，基础设施**（1.1.0 OAuth 2.0、1.3.0 CORS、1.3.0 host networking、1.6.0 Hooks）。这些变化不是用户可见的功能，而是部署和集成的"润滑剂"。host networking mode 的引入尤其值得关注——它在 1.3.0 才出现，说明早期版本的所有 Runtime 都强制使用 Docker bridge 网络。这个限制在开发环境中造成了真实的摩擦（Agent 无法访问宿主机的本地服务），host mode 的引入是对真实用户反馈的回应。

值得注意的是，1.x 系列的 release notes 中没有架构层面的重新设计。没有"重写 EventStream"、没有"替换 Runtime 实现"、没有"重构 State 管理"。这表明 1.0.0 的架构重构足够坚实，后续迭代是"在稳定地基上盖房子"——新增楼层，不改地基。对于一个 72K star 的项目，这种架构稳定性比新增功能更有长期价值。

> **图 2 插入位置**：五层产品矩阵金字塔图。底部最宽为 L1 SDK（开发者最多），向上逐层收窄至 L5 Enterprise（客户最少但单客户价值最高）。每层标注技术栈和部署模式，层间箭头标注依赖关系（L2-L5 均依赖 L1 SDK）。详见 `image-prompts/openhands-architecture.md` 图 2。
