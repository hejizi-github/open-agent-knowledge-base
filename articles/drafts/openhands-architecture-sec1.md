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
