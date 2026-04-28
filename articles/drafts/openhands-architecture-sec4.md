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
