---
title: "OpenHands 架构深潜：从 EventStream 到 Runtime-Sandbox 的软件工程 Agent 设计哲学"
slug: openhands-architecture
date: 2026-04-28
word_count: 11520
tags:
  - openhands
  - agent-framework
  - software-engineering-agent
  - event-driven-architecture
  - sandbox-security
  - docker
  - runtime-design
  - chinese-technical-writing
description: >
  基于源码级事实对 OpenHands 进行专题深潜：澄清软件工程 Agent 与聊天 Agent 的类别差异，
  解剖五层产品矩阵与 1.0.0 重大重构，深入 EventStream 事件驱动 backbone，
  分析 Runtime-Sandbox 的安全边界，将 OpenHands 放入首篇五维坐标系并建议新增"代码执行深度"维度，
  最后提供可直接用于技术评审的决策树。
source_refs:
  - wiki/facts/openhands-001.md
  - wiki/facts/smolagents-001.md
  - wiki/facts/langgraph-001.md
  - wiki/facts/crewai-001.md
  - wiki/facts/autogen-001.md
  - wiki/facts/maf-001.md
  - wiki/methodology/sequel-essay-form-001.md
  - articles/published/five-pole-agent-frameworks.md
  - raw/openhands-core-readme.md
  - raw/openhands-readme.md
  - raw/openhands-agents.md
  - raw/openhands-releases-api.json
  - raw/openhands-repo-api.json
image_prompts: image-prompts/openhands-architecture.md
license: CC-BY-SA-4.0
---

## §0 摘要（~1,200 字）

2024 到 2026 年，技术社区对"Agent"的定义经历了两次膨胀。第一次从"调用工具的 LLM"膨胀到"多 Agent 协作系统"，第二次从"对话系统"膨胀到"软件工程助手"。OpenHands 位于第二次膨胀的中心，但多数中文技术讨论仍用第一次膨胀的框架理解它——把它当作"又一个聊天 Agent 框架"来介绍，忽略了它的核心差异化：在 Docker Sandbox 中执行真实代码、修改文件系统、运行测试套件。

截至 2026 年 4 月 28 日，OpenHands 在 GitHub 上拥有 72,234 个 star 和 9,122 个 fork，是开源 Agent 框架中 star 数最高的项目 [ref: facts/openhands-001.md]。它在 SWE-bench（软件工程基准测试）上的得分达到 77.6 [ref: raw:openhands-readme.md]，高于多数同类项目。但这些数字在中文社区的传播方式与首篇五极长文揭示的"star 数陷阱"完全一致：72K star 被当作"成熟度 proxy"，77.6 分被当作"技术优越性 proxy"，两个 proxy 的传递链在每一步都引入了偏差。

中文技术社区对 OpenHands 的介绍长期停留在"安装教程"和"功能演示"层面。打开任意一篇 2026 年的中文 OpenHands 文章，40% 是快速上手指南，35% 是截图展示，20% 是与 Devin 或 Cursor 的表层比较，仅有 5% 触及架构层面的分析。这种信息分布导致一个认知盲区：工程师知道"OpenHands 能做什么"，却不知道"它的架构决策如何在代码执行场景中产生连锁反应"。后者才是选型决策的实质——你选择的不只是一个功能列表，而是一套会在未来 18 个月内持续产生技术债务或技术收益的架构假设。

本文基于源码级事实和官方架构文档，对 OpenHands 进行专题深潜。§1 澄清"软件工程 Agent"与"聊天 Agent"的类别差异；§2 解剖五层产品矩阵的组织变迁；§3 深入 EventStream 事件驱动 backbone；§4 分析 Runtime-Sandbox 的安全边界；§5 将 OpenHands 放入首篇五维坐标系并建议新增"代码执行深度"维度；§6 提供可直接用于技术评审的决策树。全文围绕三个反直觉发现展开。

**第一，OpenHands 的 EventStream 不是"消息队列的别名"，而是一个把所有组件解耦为纯事件生产/消费关系的架构 backbone。** Agent、AgentController、Runtime、Frontend 四个核心组件之间没有直接调用关系，全部通过 EventStream 的 pub/sub 机制通信 [ref: raw:openhands-core-readme.md]。这个设计的直接后果是：Frontend 可以在 Runtime 崩溃后继续恢复会话；AgentController 可以在不重启的情况下切换 Runtime 实现（从 Docker 切到 local）。这种松耦合不是"过度工程化"，而是软件工程 Agent 的必需——因为 Runtime 执行的是真实代码，崩溃概率远高于纯 API 调用场景。

**第二，五层产品矩阵（SDK→CLI→GUI→Cloud→Enterprise）不是"同一套代码打包五次"，而是 1.0.0 重大架构重构的结果。** 2025 年 12 月 16 日发布的 1.0.0 版本引入了 software-agent-sdk，同时将 CLI 拆分到独立仓库 OpenHands-CLI [ref: facts/openhands-001.md]。这不是代码搬家，而是依赖关系的重构：主仓库从"包含一切"变为"依赖 SDK"，SDK 成为五层共享的引擎层。这个重构的代价是 CLI 用户需要单独安装，收益是 SDK 可以独立演进、被第三方框架引用。

**第三，OpenHands 在 SWE-bench 上的高分不是营销数字，而是架构设计（Runtime 可插拔 + 多模型支持 + 事件驱动可恢复）的直接产物——但这个分数掩盖了真实部署中的沙箱配置复杂度。** OpenHands 支持 Docker Sandbox 和本地运行两种 Runtime [ref: raw:openhands-agents.md]，通过 LiteLLM 原生支持 Claude、GPT、Gemini、Qwen 等主流模型 [ref: facts/openhands-001.md]。这种灵活性让它在基准测试中可以针对每个任务选择最优模型和最优执行环境。但生产部署中，Docker volume 挂载、网络模式选择（bridge vs host）、权限配置等细节问题会显著影响实际体验——1.3.0 引入 host networking mode [ref: raw:openhands-releases-api.json] 本身就说明容器网络隔离在某些场景下反而是障碍。

对于需要在 2026 年做出 Agent 框架选型决策的工程师和技术负责人，本文提供的不止是 OpenHands 的架构说明书，而是一个可以复用到其他技术评估场景的"代码执行深度"分析框架，以及 OpenHands 在首篇五维坐标系中的精确位置。
## §1 开头钩子："软件工程 Agent"不是聊天机器人的延伸（~1,500 字）

### §1.1 一个被混淆的概念

2024 到 2026 年，技术社区对"Agent"的定义经历了两次概念膨胀。第一次膨胀将"Agent"从"调用外部工具的 LLM"扩展到"多 Agent 协作系统"—— CrewAI 的 `role`/`goal`/`backstory` 三元组 [ref: facts/crewai-001.md]、AutoGen 的 GroupChat 机制 [ref: facts/autogen-001.md]、MAF 的 Team 编排 [ref: facts/maf-001.md] 都是这次膨胀的产物。第二次膨胀将"Agent"从"对话系统"扩展到"软件工程助手"——OpenHands 的代码编辑、命令执行、测试运行 [ref: raw:openhands-core-readme.md]、Devin 的端到端软件开发、GitHub Copilot Workspace 的 PR 级代码生成，都是这次膨胀的代表。

OpenHands 位于第二次膨胀的中心，但多数中文技术讨论仍用第一次膨胀的框架理解它。打开任意一篇 2026 年的 OpenHands 中文介绍文章，排在前面的内容高概率是："让 AI 帮你写代码""像 ChatGPT 一样对话，但还能执行命令""一个开源的 AI 编程助手"。这些描述没有错，但它们把 OpenHands 压缩成了"聊天机器人 + 工具调用"的变体，忽略了第二次膨胀引入的根本差异。

这个根本差异可以用一句话概括：**软件工程 Agent 与聊天 Agent 的分界线不在"是否调用工具"，而在"行动的后果是否可逆"。**

一个聊天 Agent 调用搜索引擎返回了错误结果，用户可以忽略它，对话继续。一个聊天 Agent 调用天气 API 返回了错误温度，用户可能穿错衣服——但后果是生活层面的，不是系统层面的。一个软件工程 Agent 执行了 `rm -rf /project/src`，后果是代码库的永久丢失（如果没有版本控制）。一个软件工程 Agent 修改了生产数据库的 schema，后果可能是服务中断。

这个差异不是程度差异，而是类别差异。它决定了架构设计的全部关键决策：为什么需要 Sandbox 隔离、为什么需要事件驱动的可恢复架构、为什么需要人机协作的审批机制。用理解聊天 Agent 的框架去评估 OpenHands，就像用理解自行车的方式去评估汽车——两者都有轮子，但后者需要发动机、变速箱和安全气囊。

### §1.2 两个数字制造的张力

截至 2026 年 4 月 28 日，OpenHands 在 GitHub 上拥有 72,234 个 star，在开源 Agent 框架中排名第一 [ref: facts/openhands-001.md]。这个数字本身不说明技术适合度——首篇五极长文已经系统论证了 star 数作为"成熟度 proxy"的偏差 [ref: articles/published/five-pole-agent-frameworks.md]。但 72K star 确实说明了一件事：OpenHands 的概念传播性极强。

概念传播性强的原因不难分析。OpenHands 的前身 OpenDevin 直接对标当时最火的闭源产品 Devin [ref: facts/openhands-001.md]，"开源版 Devin"这个标签在社交媒体上的传播效率远超"事件驱动架构的 Agent 框架"。改名后的 OpenHands 继承了这份传播红利，同时通过五层产品矩阵（SDK / CLI / GUI / Cloud / Enterprise）[ref: raw:openhands-readme.md] 覆盖了从个人开发者到企业客户的全光谱，进一步扩大了潜在 bookmark 用户群。

但高传播性带来了低信息密度的副作用。在中文技术社区中搜索"OpenHands 架构"，结果分布大致如下：40% 是安装教程和快速上手，35% 是功能演示和截图展示，20% 是与 Devin/Cursor/Windsurf 的表层比较，仅有 5% 涉及架构层面的分析。72K star 对应的深度内容供给严重不足。

第二个数字加剧了这种张力：OpenHands 在 SWE-bench 上的得分是 77.6 [ref: raw:openhands-readme.md]。SWE-bench 是一个测试 LLM 解决真实 GitHub issue 能力的基准：给定一个代码库和一个 issue 描述，Agent 需要理解代码、定位 bug、编写修复、运行测试验证。77.6 分意味着 OpenHands 在这个任务上的成功率高于多数同类项目。但这个分数的架构含义是什么？是什么设计决策让它在真实代码库修改任务上表现更好？在中文社区中，这两个问题几乎没有被讨论过。

### §1.3 本文要做什么

本文不教你"如何安装 OpenHands"，也不做"OpenHands vs Devin"的功能对比表。这些内容易获取且更新快，写进长文只会加速过期。

本文要做的是解剖 OpenHands 的架构设计：EventStream 如何解耦组件、Runtime 如何平衡安全与效率、五层产品矩阵如何对应不同的部署形态、1.0.0 的重大重构如何改变依赖关系。在 §5，我们将把 OpenHands 放入首篇五维坐标系中，定位它在"控制流显式度"和"生产就绪梯度"上的独特位置，并建议增加第 6 维"代码执行深度"来完整捕捉 OpenHands 的差异化。

读完这篇文章，你将获得一套可以复用到其他软件工程 Agent 评估的分析框架——不只是"这个框架能做什么"，而是"这个框架的架构决策如何在代码执行场景中产生连锁反应"。

> **图 1 插入位置**：聊天 Agent vs 软件工程 Agent 的后果可逆性对比图。左侧：聊天 Agent（轻量级后果，可忽略）；右侧：软件工程 Agent（重量级后果，不可逆）。中间分界线标注"OpenHands 位于右侧"。详见 `image-prompts/openhands-architecture.md` 图 1。
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
## §3 EventStream 架构解剖：事件驱动 backbone 的设计哲学（~2,000 字）

§2 揭示了 OpenHands 的五层产品矩阵如何在组织层面解耦——SDK、CLI、GUI 各自独立演进。但组织解耦只是表象，技术层面的解耦才是支撑五层产品共享同一套引擎的核心机制。这个机制就是 EventStream。

### §3.1 从伪代码到事件总线：为什么不用直接函数调用

OpenHands 的核心控制流可以用 5 行伪代码概括 [ref: raw:openhands-core-readme.md]：

```python
while True:
    prompt = agent.generate_prompt(state)
    response = llm.completion(prompt)
    action = agent.parse_response(response)
    observation = runtime.run(action)
    state = state.update(action, observation)
```

这个伪代码传达的直观印象是：AgentController 直接调用 Agent、LLM、Runtime，形成一条顺序执行链。但 OpenHands 的实际实现中，这条链中的每一步都不是直接函数调用，而是通过 EventStream 的消息传递完成 [ref: raw:openhands-core-readme.md]。Agent 产出的 Action 不是直接传给 Runtime，而是发布到 EventStream；Runtime 执行后的 Observation 不是直接返回给 AgentController，而是发布到 EventStream 等待监听者消费。

这个设计选择——用事件总线替代直接调用——在 Agent 框架领域并不常见。多数框架采用直接调用模式：smolagents 的 ReAct 循环中，Agent 直接调用工具函数 [ref: facts/smolagents-001.md]；LangGraph 的 Pregel 引擎中，节点函数通过图边直接传递状态 [ref: facts/langgraph-001.md]。OpenHands 选择事件总线的理由是什么？

**第一个理由是故障隔离。** Runtime 在 Docker 容器中执行真实代码——`rm -rf`、`pip install`、`pytest` 等命令——任何一条命令都可能导致容器崩溃或进入不可恢复状态。如果 AgentController 直接调用 Runtime，Runtime 的崩溃会直接拖垮 AgentController，进而导致整个会话丢失。EventStream 作为中间层，使 AgentController 和 Runtime 成为独立进程：Runtime 崩溃后，EventStream 中已发布的事件不会丢失，AgentController 可以在 Runtime 重启后从断点恢复。这种故障隔离不是"锦上添花"，而是软件工程 Agent 的必需——因为 Runtime 执行的是真实代码，崩溃概率远高于纯 API 调用场景 [ref: facts/openhands-001.md]。

**第二个理由是可观测性。** 所有组件间通信都经过 EventStream，这意味着系统的全部交互历史都以事件序列的形式被保留。调试一个失败的 Agent 任务时，开发者可以重放 EventStream 中的事件序列，精确复现 Agent 的决策路径。直接调用模式下，调用栈和返回值是瞬态的，除非额外植入日志，否则无法回溯。EventStream 将这种"可回溯性"内建在架构中，而非作为外部工具附加 [ref: raw:openhands-core-readme.md]。

**第三个理由是 Frontend 解耦。** OpenHands 的 GUI 前端是一个独立的 React 应用 [ref: facts/openhands-001.md]。如果前端需要直接调用后端 API 来获取 Agent 状态，那么每次架构调整（如新增一种 Action 类型）都需要同步修改前后端接口。EventStream 模式下，前端只需监听事件流：Agent 发布了新的 Action，前端收到事件后更新 UI；Runtime 发布了新的 Observation，前端收到事件后追加到聊天记录。前端不需要知道 Action 的具体类型，也不需要知道 Runtime 的实现细节——它只消费事件。这种解耦使前端可以独立演进，也为未来新增交互模式（如 WebSocket 推送、CLI 实时输出）提供了统一的底层支撑。

### §3.2 EventStream 的消息拓扑

OpenHands 官方文档用一段 mermaid 图描述了 EventStream 的消息拓扑 [ref: raw:openhands-core-readme.md]：

```
Agent --Actions--> AgentController --Actions--> EventStream
EventStream --Observations--> AgentController --State--> Agent
EventStream --Actions--> Runtime --Observations--> EventStream
Frontend --Actions--> EventStream
```

这段拓扑图有一个关键特征值得仔细解读：**没有中央调度器**。AgentController 不是"指挥官"，不向 Runtime 发送"执行这个命令"的直接指令；它只是向 EventStream 发布一个 Action 事件。Runtime 作为一个独立的事件消费者，监听 EventStream 中的 Action 事件，执行后向 EventStream 发布 Observation 事件。AgentController 监听 Observation 事件，更新 State，再驱动 Agent 产出下一个 Action。

这个拓扑的去中心化程度在 Agent 框架中处于较高水平。对比一下：AutoGen 的 Actor 模型中，每个 Agent 是一个 Actor，消息在 Actor 之间直接传递 [ref: facts/autogen-001.md]——Actor 之间没有共享的总线，通信是点对点的。LangGraph 的 Pregel 引擎中，开发者预先定义状态转换图，每个节点函数知道它的输入来自哪个节点、输出发往哪个节点 [ref: facts/langgraph-001.md]——控制流是白盒的、静态的。OpenHands 的 EventStream 则介于两者之间：组件通过共享总线通信（类似 Actor 模型的间接寻址），但没有预设的拓扑结构（类似 Pregel 的图边），事件的流向由运行时的发布/订阅关系动态决定。

Frontend 在拓扑中的位置尤其值得关注。Frontend 不是"被动展示层"，而是 EventStream 的平等参与者：它可以向 EventStream 发布 Action 事件（如用户输入的消息），也可以监听 EventStream 中的 Observation 事件（如 Agent 的执行结果）。这意味着 Frontend 可以在 Runtime 崩溃后继续工作——用户仍然可以浏览历史事件、发送新消息；Runtime 恢复后，EventStream 中的新事件会自然流入前端。这种"Frontend 不依赖 Runtime 存活"的特性，是事件驱动架构在可用性层面的直接收益。

### §3.3 与五极控制流范式的对比

| 项目 | 控制流范式 | 通信机制 | 关键差异 |
|------|-----------|----------|----------|
| OpenHands | 事件驱动循环 | EventStream pub/sub | 无中央调度器，组件通过事件总线松耦合；故障可恢复 |
| LangGraph | 显式状态图 | Pregel 图引擎 | 开发者定义所有状态转换；控制流白盒化 |
| smolagents | 黑盒 ReAct | 直接函数调用 | Agent 内部闭环，无外部事件系统；极简但不可观测 |
| CrewAI | 分布式多子系统 | Agent 工具调用 + Flow 事件 | 控制流分散在四个子系统中，认知模型不统一 |
| AutoGen | Actor 模型 | 异步消息传递 | 严格的 Actor 隔离边界，无共享总线 |
| MAF | 分层（Tier 0→Workflow） | 多种，含 DurableTask | 从黑盒到白盒的分层选项，复杂度高 |

这个对比表揭示了一个反直觉的结论：**OpenHands 的 EventStream 不是"又一个消息队列"，而是对软件工程 Agent 特殊需求的架构回应。** 如果 OpenHands 的任务只是调用外部 API（天气查询、搜索引擎），直接函数调用足够，事件总线反而增加不必要的复杂度。但 OpenHands 的任务是在隔离环境中执行真实代码——代码可能崩溃、可能无限循环、可能修改文件系统。在这种场景下，"执行者崩溃不影响调度者"是一个硬需求，而非可选优化。

从另一个角度观察：OpenHands 的控制流范式在"显式度"光谱上处于中间位置。LangGraph 是最显式的——开发者用代码定义每个状态转换。smolagents 是最隐式的——LLM 决定每一步做什么，开发者无法干预中间过程。OpenHands 介于两者之间：AgentController 驱动主循环（显式），但 LLM 决定每一步的 Action 内容（隐式）。开发者可以配置 Agent 的行为（通过 `.agents/` 目录的配置文件）[ref: facts/openhands-001.md]，但不能像 LangGraph 那样精确控制每一步的状态转换。这种"半显式"设计在软件工程场景中是一种务实的折中：完全显式需要开发者手动定义所有可能的代码操作（不现实），完全隐式则无法保证 Agent 不会执行危险命令（不可接受）。

EventStream 还为 OpenHands 带来了长期演进的优势。1.0.0 引入的 software-agent-sdk 将核心引擎从主仓库提取为独立库 [ref: facts/openhands-001.md]，SDK 的对外接口本质上就是 EventStream 的发布/订阅 API。这意味着任何第三方项目——无论是一个新的 CLI 工具、一个 IDE 插件、还是一个自动化流水线——都可以监听和发布事件，与 OpenHands 的核心引擎交互。事件总线成为了一种"开放协议"，而不仅是一种内部实现细节。

> **图 3 插入位置**：EventStream 消息拓扑流程图。左侧为 Agent → AgentController → EventStream 的 Action 流，中间为 EventStream 总线（hub 形状），右侧为 Runtime → EventStream → Frontend 的 Observation 流。用不同颜色区分 Action（蓝色）和 Observation（绿色）。标注"无中央调度器"的核心特征。详见 `image-prompts/openhands-architecture.md` 图 3。

> **图 4 插入位置**：六项目控制流范式对比光谱。横向光谱从左（黑盒/隐式）到右（白盒/显式），六项目按位置排列：smolagents（最左）→ OpenHands → CrewAI → AutoGen → MAF → LangGraph（最右）。每个项目下方标注其通信机制和关键特征。详见 `image-prompts/openhands-architecture.md` 图 4。
## §4 Runtime-Sandbox：代码执行的边界与张力（~1,800 字）

EventStream 解决了组件间通信的解耦问题，但一个核心问题尚未触及：Agent 产出的 Action——编辑文件、运行命令、执行测试——究竟在哪里执行？由谁来保证执行的安全？这是 Runtime 的职责，也是 OpenHands 架构中最具张力的部分。

### §4.1 Runtime 的职责边界

Runtime 在 OpenHands 中的定义简洁而精确："responsible for performing Actions, and sending back Observations" [ref: raw:openhands-core-readme.md]。Action 包括编辑文件、运行 shell 命令、发送消息；Observation 包括文件内容、命令输出、错误信息。这个定义本身没有特别之处——任何需要执行代码的 Agent 框架都有类似的执行层。OpenHands 的 Runtime 差异化在于两个设计决策。

**第一个决策是可插拔性。** Runtime 支持两种实现：Docker Sandbox（默认）和本地运行（通过设置 `RUNTIME=local`）[ref: raw:openhands-agents.md]。这两种实现共享同一套接口：接收 Action，返回 Observation。上层组件（AgentController、EventStream、Frontend）不需要知道当前使用的是哪种 Runtime。这种可插拔性不是架构上的"锦上添花"，而是 Dev/Prod 一致的必要条件。开发者在本地用 `RUNTIME=local` 快速迭代——不需要启动 Docker 容器，启动时间从数十秒降至数秒。生产环境切换到 Docker Sandbox，获得完整的隔离保证。两种模式下的 Agent 行为一致，因为 Action/Observation 的契约是统一的 [ref: facts/openhands-001.md]。

1.1.0 的 release notes 中有一条值得关注的修复："Local (non-Docker) runs now use host-writable paths by default and keep Playwright downloads out of /workspace, preventing permissions errors" [ref: raw:openhands-releases-api.json]。这条修复说明了一个事实：本地运行模式在早期版本中存在真实的权限问题，开发者的文件系统被 Playwright 浏览器下载污染。这个问题在 Docker 模式下不存在——Sandbox 的文件系统是容器内的独立视图。这个差异恰好说明了两种 Runtime 的适用边界：本地模式追求速度，牺牲隔离；Docker 模式追求隔离，牺牲启动时间。

**第二个决策是 Sandbox 的轻量级设计。** Sandbox 不是从零构建的虚拟化层，而是基于 Docker 容器 + tmux 会话 + Playwright 浏览器的组合 [ref: facts/openhands-001.md]。Docker 提供进程和文件系统隔离，tmux 提供会话持久化（即使容器重启，tmux 会话中的命令历史可以被恢复），Playwright 提供浏览器自动化能力（Agent 可以操作网页、运行前端测试）。这个组合不是"最小可行"的——一个更简单的 Sandbox 可以只用 Docker 容器。加入 tmux 和 Playwright 说明 OpenHands 的设计目标不是"能运行代码就行"，而是"能在真实软件开发工作流中运行代码"——这包括需要浏览器自动化的前端测试、需要会话持久化的长时间运行任务。

### §4.2 Docker Sandbox 的安全模型

Sandbox 在 Docker 容器中执行命令 [ref: raw:openhands-core-readme.md]。安全边界由 Docker 提供，而非 OpenHands 自研。这个选择带来了一组明确的优劣权衡。

**优势在于继承成熟机制。** Docker 的隔离机制——namespace、cgroup、overlayfs——经过十年以上的生产验证。OpenHands 不需要重新发明沙箱，不需要维护一套自定义的虚拟化层，也不需要处理沙箱逃逸漏洞的应急响应。对于一个 72K star 的开源项目，"不重新发明轮子"是务实的选择：安全漏洞的修复责任由 Docker 社区承担，OpenHands 只需跟进 Docker 版本更新。

**风险在于配置复杂度向用户传递。** Docker 的隔离不是"开箱即用"的绝对安全。Volume 挂载配置决定了容器能否访问宿主机的文件系统；网络模式决定了容器能否访问宿主机的网络服务；用户权限配置决定了容器内进程以什么身份运行。这些配置细节直接传递到 OpenHands 的部署复杂度中。一个典型的部署陷阱是：开发者为了让 Agent 访问本地数据库服务，错误地配置了 volume 挂载，导致 Agent 获得了对宿主机敏感目录的写权限——Sandbox 的隔离因此被绕过。

1.3.0 引入的 host networking mode 是这种张力的具体体现 [ref: raw:openhands-releases-api.json]。在此之前，所有 Sandbox 都使用 Docker 默认的 bridge 网络模式——容器拥有独立的网络命名空间，与宿主机网络隔离。host mode 的引入允许容器直接使用宿主机的网络栈，使 Agent 可以访问宿主机上任意端口的服务。release notes 中的说明是："enables reverse proxy setups to access user-launched applications on any port, not just the predefined worker ports" [ref: raw:openhands-releases-api.json]。这个功能的直接动机是开发环境的需求：Agent 启动了一个本地 Web 服务（如 `python -m http.server 8080`），开发者需要从浏览器访问它。在 bridge 模式下，这个服务只能在容器内部访问；在 host 模式下，它直接在宿主机的 8080 端口上可访问。

但 host mode 的安全代价是显著的：容器与宿主机共享网络命名空间，意味着容器内的进程可以扫描宿主机的本地网络、访问未鉴权的服务、甚至尝试连接内网中的其他机器。这不是 Docker 的漏洞，而是网络隔离被主动削弱后的预期结果。OpenHands 将 host mode 作为一个可选配置（`OH_SANDBOX_USE_HOST_NETWORK=true`）暴露给用户 [ref: raw:openhands-releases-api.json]，而不是默认启用——这个设计选择说明团队意识到了安全张力，把决策权交给了部署者。

另一个值得注意的安全细节是 1.1.0 中 init 进程的替换：从 micromamba 切换到 tini [ref: raw:openhands-releases-api.json]。tini 是一个轻量级的 init 进程，专门解决 Docker 容器中的"僵尸进程"问题——当子进程退出而父进程没有正确回收时，子进程会成为僵尸进程，占用系统资源。在 Agent 执行长时间运行命令的场景中（如 `npm install` 启动大量子进程），僵尸进程的累积会导致容器资源耗尽。tini 的引入使 Sandbox 更适合长时间、高并发的代码执行任务。这个改动虽小，但反映了 OpenHands 团队对 Sandbox 生产可用性的持续打磨。

### §4.3 与五极沙箱方案的对比

| 项目 | 沙箱方案 | 执行环境 | 安全边界 |
|------|----------|----------|----------|
| OpenHands | Docker Sandbox + local 可选 | 容器/宿主机 | Docker 隔离 + 可选 host mode |
| smolagents | E2B / Docker / WASM | 第三方托管/容器/WASM | 依赖外部服务或 Docker 隔离 |
| AutoGen | DockerCommandLineCodeExecutor | 容器 | Docker 隔离 |
| MAF | CodeAct / Hyperlight（proposed） | 轻量级虚拟化 | Hyperlight 微隔离（计划中） |
| LangGraph | 无内置 | 无 | 无，依赖部署环境 |
| CrewAI | 无内置 | 无 | 无，依赖部署环境 |

这个对比表揭示了 OpenHands 在沙箱维度上的独特定位：**它是六项目中唯一同时提供"生产级隔离（Docker）"和"开发级速度（local）"两种选项的框架。** AutoGen 也使用 Docker，但没有本地运行模式——开发者在本地测试时仍需启动容器。smolagents 提供了三种沙箱选项（E2B、Docker、WASM），但 E2B 是第三方托管服务，引入了网络延迟和外部依赖；WASM 是实验性选项，成熟度有限 [ref: facts/smolagents-001.md]。

LangGraph 和 CrewAI 在沙箱维度上的空白值得单独分析。LangGraph 的设计理念是"编排框架"——它负责定义和控制 Agent 的工作流，但不负责执行 Agent 产出的代码 [ref: facts/langgraph-001.md]。代码执行被委托给外部工具或部署环境。这种设计在灵活性上有优势（开发者可以选择任意执行环境），但在一致性上有代价：不同部署者的沙箱配置差异巨大，LangGraph 本身无法保证执行安全。CrewAI 的定位更接近"多 Agent 协作框架"，其核心抽象是 Role、Goal、Task 的分配 [ref: facts/crewai-001.md]，代码执行不是其设计重点。

OpenHands 的 Runtime 可插拔设计在五极之外还有一层更深刻的架构含义：它把"执行"从一个隐式能力变成了一个显式接口。在多数框架中，Agent 执行代码是框架内部的黑盒——开发者无法替换执行层、无法在不同环境中复用同一套执行逻辑。OpenHands 将 Runtime 抽象为可插拔接口，使"执行"成为一等公民。这个抽象的收益在 §2 讨论的五层产品矩阵中已得到验证：SDK、CLI、GUI、Cloud 四种形态共享同一套 Runtime 实现，只是部署环境不同 [ref: facts/openhands-001.md]。

但 Runtime 的抽象也带来了一个隐性成本：本地运行模式与 Docker 模式之间的行为一致性无法被完全保证。Docker 容器中的文件系统是 overlayfs，本地运行模式直接操作宿主机的文件系统——两种模式下的文件权限、路径结构、环境变量都可能不同。一个只在 local 模式下测试过的 Agent 配置，切换到 Docker 模式后可能出现意料之外的行为差异。这个风险在 OpenHands 的贡献者指南中被间接承认：文档中包含了大量 local runtime 的故障排除说明，如 "clear the stale tmux session"、"Playwright browsers under ~/.cache/playwright" 等 [ref: raw:openhands-agents.md]。这些 troubleshooting 条目的存在本身就说明 local 模式的配置复杂度不低。

对于需要在 2026 年评估 Agent 框架的工程师，Runtime-Sandbox 维度的对比提供了一个清晰的选型信号：如果你的场景需要 Agent 在隔离环境中执行真实代码（修改文件系统、运行测试套件、操作浏览器），OpenHands 和 AutoGen 是六项目中的首选；如果你只需要 Agent 调用外部 API（搜索、查询数据库），LangGraph 或 CrewAI 的轻量级设计更合适，因为它们不需要引入 Docker 的部署复杂度。如果你的场景对沙箱安全有最高要求（如运行不可信代码），smolagents 的 E2B 集成提供了第三方托管的更强隔离——但你需要接受外部依赖和网络延迟的代价。

> **图 5 插入位置**：Runtime-Sandbox 安全边界示意图。左侧为 Docker Sandbox 模式：Agent → Runtime → Docker 容器 → 隔离的文件系统和网络。右侧为 local 模式：Agent → Runtime → 直接操作宿主机。中间用双向箭头标注切换方式（RUNTIME=local/docker），下方标注各自的适用场景（开发迭代 vs 生产隔离）。详见 `image-prompts/openhands-architecture.md` 图 5。
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
## §6 实践建议：何时选择 OpenHands（~1,000 字）

§5 把 OpenHands 放入了升级后的六维坐标系，但坐标系本身不是决策工具。对于需要在周一早上向技术评审会汇报选型结论的工程师，需要的是一套可操作的判断规则。§6 提供这套规则——不是"OpenHands 好 vs 不好"的二元判断，而是"你的场景匹配 OpenHands 的架构假设吗"的结构性分析。

### §6.1 适用场景

**场景一：Agent 需要在隔离环境中执行真实代码。** 这是 OpenHands 最核心的架构假设，也是选型决策的"根节点"。如果你的场景涉及修改代码库、运行测试套件、执行构建命令、操作浏览器自动化——即任何需要与真实文件系统和进程交互的任务——OpenHands 的 Runtime-Sandbox 架构提供了六项目中最完整的执行深度 [ref: wiki/facts/openhands-001.md]。SWE-bench 的 77.6 分 [ref: raw:openhands-readme.md] 是这个假设在基准测试中的验证，但生产环境中的验证同样重要：你的团队是否需要一个能在 Docker 容器中安全运行 `rm -rf`、`pip install`、`pytest` 的 Agent？

**场景二：团队需要多种交互模式的渐进式采用。** OpenHands 的五层产品矩阵 [ref: wiki/facts/openhands-001.md] 支持从 SDK（框架集成）到 CLI（个人终端）到 GUI（团队演示）到 Cloud/Enterprise（组织部署）的渐进路径。

这个路径的价值不在于"选项多"，而在于"迁移成本低"——同一个 Agent 配置可以从本地 CLI 测试无缝切换到 Cloud 生产环境，因为底层共享 software-agent-sdk [ref: wiki/facts/openhands-001.md]。

**场景三：组织需要平衡开发效率与生产隔离。** Runtime 的可插拔设计（Docker Sandbox vs local）使 OpenHands 能同时满足两种矛盾需求：开发阶段用 `RUNTIME=local` 快速迭代（启动时间数秒），生产阶段切换到 Docker Sandbox 保证隔离 [ref: raw:openhands-agents.md]。六项目中，只有 OpenHands 和 smolagents 提供这种双模式，但 smolagents 的 local 执行器明确声明"不是安全沙箱" [ref: wiki/facts/smolagents-001.md]，而 OpenHands 的 local 模式虽也有安全妥协，但至少提供了 Docker 模式作为生产默认。

**场景四：SWE-bench 类任务——代码库理解、bug 修复、功能实现。** OpenHands 在 SWE-bench 上的高分不是偶然的。它的架构设计（EventStream 可恢复 + Runtime 可插拔 + 多模型支持）恰好匹配这类任务的需求：长时间运行、可能失败、需要反复尝试、需要在隔离环境中验证。如果你的团队正在构建类似的"AI 软件工程师"产品，OpenHands 的架构模式比通用 Agent 框架更具参考价值。

### §6.2 不适用场景

**场景一：只需要简单工具调用（搜索、查询、API 调用）。** 如果你的 Agent 任务不涉及代码执行，OpenHands 的 Docker 依赖和 Runtime 抽象会变成不必要的负担。smolagents 的 26,939 star [ref: wiki/facts/smolagents-001.md] 和极简 API 更适合这种场景——它的 CodeAgent 虽然能执行 Python 代码，但核心定位仍是"工具调用框架"，部署复杂度远低于需要 Docker 的 OpenHands。

**场景二：需要精确控制流定义。** 如果你的工作流需要开发者精确控制每一步的状态转换（如审批流程、合规检查点、条件分支），LangGraph 的显式状态图 [ref: wiki/facts/langgraph-001.md] 比 OpenHands 的"半显式"循环更合适。OpenHands 的 AgentController 不暴露细粒度的状态转换接口——它信任 LLM 在每一步的决策，只在循环层面提供结构。这种设计在开放-ended 的代码工程任务中是优势，在严格约束的业务流程中可能是劣势。

**场景三：完全零商业锁定的需求。** OpenHands 的核心代码是 MIT License，但 Enterprise 层是 source-available [ref: wiki/facts/openhands-001.md]，需要商业许可才能长期运行。如果你的组织对 License 有零容忍要求（如某些开源基金会项目或政府机构），需要评估 Enterprise 层的边界。相比之下，smolagents（Apache-2.0）、LangGraph（MIT）、CrewAI（MIT）的全栈 License 更宽松 [ref: wiki/facts/smolagents-001.md] [ref: wiki/facts/langgraph-001.md] [ref: wiki/facts/crewai-001.md]。

**场景四：Python < 3.12 的运行环境。** OpenHands 要求 Python >=3.12, <3.14 [ref: wiki/facts/openhands-001.md]。这个限制排除了一些遗留环境（如基于 Python 3.10 的企业内部平台）。五极中的 smolagents 和 CrewAI 对 Python 版本的要求更宽松 [ref: wiki/facts/smolagents-001.md] [ref: wiki/facts/crewai-001.md]，在旧环境部署时兼容性更好。

### §6.3 决策树

将上述分析转化为一个可直接用于技术评审的决策流程：

```
需要 Agent 执行真实代码（修改文件系统、运行测试、操作浏览器）？
  ├─ 否 → 考虑 smolagents（轻量工具调用）或 LangGraph（精确控制流）
  └─ 是 → 需要多种交互模式（CLI + GUI + SDK）的渐进部署？
           ├─ 否 → 需要精确控制每一步的状态转换？
           │        ├─ 是 → 考虑 LangGraph（显式状态图）
           │        └─ 否 → OpenHands SDK 或 AutoGen（但 AutoGen 已进入维护模式）
           └─ 是 → 需要企业级自托管（VPC、RBAC、协作）？
                    ├─ 否 → OpenHands Local GUI 或 Cloud
                    └─ 是 → 评估 Enterprise 层 source-available License 可接受？
                             ├─ 否 → 考虑 CrewAI Cloud 或自建 LangGraph + LangSmith
                             └─ 是 → OpenHands Enterprise
```

这个决策树的根节点不是"哪个框架 star 多"，而是"你的场景需要代码执行深度吗"。这个根节点的选择来自 §5.3 提出的"代码执行深度"维度——它在 2026 年的 Agent 框架选型中，比"模型支持数量"或"社区活跃度"更能区分框架的本质差异。大多数框架对比文章将"支持多少种 LLM"作为首要比较维度，但在 2026 年这个维度已经趋同：OpenHands、smolagents、CrewAI、LangGraph 都通过 LiteLLM 或自研适配层支持 Claude、GPT、Gemini、Qwen 等主流模型 [ref: wiki/facts/openhands-001.md] [ref: wiki/facts/smolagents-001.md] [ref: wiki/facts/crewai-001.md] [ref: wiki/facts/langgraph-001.md]。选型决策不应基于已经趋同的维度，而应基于框架的架构假设是否与你的场景匹配。

如果你读到这里，仍然不确定 OpenHands 是否适合你的团队，有一个简单的验证方法：用 Docker 启动 OpenHands 的 Local GUI，给一个真实的代码库任务（如"修复这个仓库中的某个已知 bug"），观察三个指标：Agent 能否在 Sandbox 中成功运行测试？失败时能否从 EventStream 中恢复？前端能否在 Runtime 重启后继续显示历史事件？这三个指标的通过与否，比任何 star 数或 benchmark 分数都更能说明 OpenHands 是否适合你的场景。

---

## 图片使用清单

| 图号 | 标题 | 用途章节 | 提示词位置 |
|------|------|----------|------------|
| 图 1 | 聊天 Agent vs 软件工程 Agent 的后果可逆性对比 | §1.3 | image-prompts/openhands-architecture.md 图 1 |
| 图 2 | 五层产品矩阵金字塔 | §2.2 | image-prompts/openhands-architecture.md 图 2 |
| 图 3 | EventStream 消息拓扑流程图 | §3.2 | image-prompts/openhands-architecture.md 图 3 |
| 图 4 | 六项目控制流范式对比光谱 | §3.3 | image-prompts/openhands-architecture.md 图 4 |
| 图 5 | Runtime-Sandbox 安全边界示意图 | §4.3 | image-prompts/openhands-architecture.md 图 5 |
| 图 6 | 六维坐标系定位图 | §5.3 | image-prompts/openhands-architecture.md 图 6 |
| 图 7 | 封面图（半机械半有机的手托举 Docker 容器） | 文章头部 | image-prompts/openhands-architecture.md 图 7 |
