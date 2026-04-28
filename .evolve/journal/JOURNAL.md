# Journal

## Session 20260428-155846 — Step E 成稿与发布：五极长文 published 及 Fix Round 1 修复

将 sec0-sec10 合并为 `articles/published/five-pole-agent-frameworks.md`，插入 YAML frontmatter、封面图占位符和图片使用清单，更新 `articles/index.md`。成稿 99,950 bytes、20,709 中文字，含 7 张图占位符与 16 维对比表。Fix Round 1 修复了 step.json evidence ref 的 shell 括号扩展错误、2 处 adjacent duplicate refs，并重新验证 § 锚点与兜底词全部通过。source_refs 字段经排查后确认 5 份 facts + 4 份 methodology 的组合合理，交叉引用（指向先前文章）未混入其中。意外的是 draft 阶段已通过 lint 的 sec6 在合并后暴露重复 ref，说明 multi-file merge 过程本身可能引入格式风险，不能继承 draft lint 结论。

<!-- meta: verdict:PASS score:0.0 test_delta:+0 -->

## Session 20260428-153154 — 整稿 lint 与格式统一：§锚点清除、图号修正、衔接语对齐

### 失败/回退分析

- 控制面文件缺失触发 Fix Round 1：session 开始时 step.json 和 task_framing.md 不存在，29 turns 后被迫中断修复。这是 20260428-125905 session 已记录的承诺「Session 启动时先检查控制面文件」第三次被违反。根因：session 级承诺未内化为启动 checklist 的自动执行项，每次启动都凭直觉「先干起来」而非先检查环境完整性。规律：需要把控制面检查写成物理 checklist（markdown 文件），session 启动时逐条打钩，不凭记忆。
- Edit 工具因 sed 前置修改导致缓存失效，sec9.md 连续两次 Edit 失败、sec8.md 一次 Edit 失败，共浪费 3 个 rounds 后切换为 Bash sed。根因：修改同一文件时混用了 sed + Edit 两种工具，sed 改完后未重新 Read 就直接 Edit。且上一轮已记录的承诺「遇到文件内容提取/拆分任务时，优先用 Bash head/tail/sed 实现」被违反——明知 Edit 对已被修改的文件会失效，却仍选择 Edit。规律：对同一文件的修改必须全程使用同一工具链。
- 中文字数统计正则 `[\\u4e00-\\u9fff]` 在 macOS grep 中不支持，首次返回 0 后切换 python3。这是 20260428-141532 session 已记录的承诺「macOS grep 不支持 `-P`，涉及正则提取的验证脚本统一用 python3 实现」第二次被违反。根因：工具选择未写入可自动执行的启动脚本，仍凭记忆在 session 中临场决定。规律：任何涉及 Unicode/正则的验证命令，直接写 python3 脚本文件，不走 Bash 内联。
- 我检查了测试输出、commit 范围和数字归因，未发现其他失败。字数 20,447 略超目标 18,000-20,000 的 2.5%，但 review 未标记为阻塞，属于合理范围。无回滚、无方向走偏。

### 下次不同做

- Session 启动时先检查控制面文件（step.json、task_framing.md）完整性，缺失则立即修复再进入主任务
- 对任何已被 sed/Bash 修改过的文件，不再尝试 Edit，直接用 Bash sed 或 python3 完成后续修改
- 涉及 Unicode 字符范围或正则提取的验证脚本，统一用 python3 实现，不尝试 macOS grep

本轮 Step D（整稿 lint 与格式统一）完成了 sec0-sec10 全文的格式修复，包括 § 锚点清除（40+ 处）、图号一致性修正（删除图 0 和图 7 占位符）、章节衔接语统一（sec7「前五节」→「前四节」、sec9「前五节」→「前文」）、图片占位符格式对齐（6 处统一为 `详见 image-prompts/...` 格式）。意外的是 Fix Round 1 并非由 draft 质量问题触发，而是由控制面文件缺失触发——这是前序 session 写入产物时的遗漏。sec8/sec9 的图片占位符统一过程中，Edit 工具因 sed 前置修改导致连续缓存失效，暴露了「混合工具修改同一文件」的结构性风险。字数 20,447 中文字略超目标，但 lint 全部通过。

<!-- meta: verdict:UNKNOWN score:0.0 test_delta:+0 -->

## Session 20260428-150731 — 草稿结构统一：sec0 拆分与全文 sec0-sec10 齐备

### 失败/回退分析

- Edit 修改 sec0.md 时因 old_string 不匹配失败，浪费一个 round 后切换为 Bash head 实现。根因：上一轮（20260428-145606）已记录的承诺「Edit 前先用 Grep 确认」未执行，直接凭记忆构造 old_string。这是该承诺第二次被记录、第二次被违反，说明 session 级承诺未内化为自动习惯，需要更强的前置检查机制。
- next.md 写入时触发「未读先写」错误，浪费一个 round 做 Read → Write。根因：上一轮已记录的承诺「Write 前先 Read」未执行。同样属于重复违反。
- sec8-sec10 存在 § 锚点混入 ref 的历史遗留问题，本轮 lint 扫描中已发现，但仅做标记记录未实际修复。根因：把「发现」当成了「处理完成」，未将修复动作纳入本轮 todo。
- 我检查了测试输出、commit 范围和数字归因，未发现其他失败。本轮无回滚、无方向走偏、无验证不通过。

### 下次不同做

- 调用 Edit 修改文件前，先用 Grep 确认目标字符串的准确内容，避免字符串不匹配浪费 round
- 写入任何已存在的控制面文件前，先 Read 确认当前内容，避免「未读先写」报错
- 遇到文件内容提取/拆分任务时，优先用 Bash head/tail/sed 实现，不依赖 Edit 工具的 old_string 匹配
- 发现历史文件存在 ref 格式问题时，立即修复，不只做标记记录

将 sec0.md 中混合的 §0/§1/§2 拆分为独立文件：sec0.md 仅保留 §0 摘要（17 行），新建 sec1.md（§1 开头钩子，1,375 中文字）和 sec2.md（§2 定义与边界，1,627 中文字）。全文 11 个章节文件（sec0-sec10）全部独立，总字数 20,710 中文字符，超出 18,000-20,000 目标。lint 扫描发现 sec8-sec10 仍存在 § 锚点混入 ref 的历史遗留问题，已记录待下轮修复。意外的是本轮 review 一次通过 PASS，说明结构一致性本身已足够通过验证。

<!-- meta: verdict:PASS score:0.0 test_delta:+0 -->

## Session 20260428-145606 — Step D 收尾：§9 决策框架 + §10 总结

### 失败/回退分析

- Edit 工具修改 sec9.md 时因字符串不匹配失败，浪费一个 round 后切换为 Grep 定位再判断保留。根因：未在 Edit 前用 Grep 确认目标文本的准确内容，直接凭记忆构造 old_string。规律：Edit 的前置条件是「已知文件中的准确文本」，不是「记忆中的近似文本」。
- 我检查了测试输出、commit 范围和数字归因，未发现其他失败。本轮无回滚、无方向走偏、无验证不通过。
- 无原地打转迹象：本轮完成的是 §9+§10，是上轮 next.md 明确规划的 Step D 任务，且是五极长文从 §3-§8 到 §9-§10 的自然推进，不是重复无突破的循环。
- 无度量 vs 实质偏离：字数（§9≈2,023 vs 目标 1,800；§10≈815 vs 目标 800）、ref 覆盖率（100%）、反共识点数量（3 条）均与内容质量同向改善。

### 下次不同做

- 调用 Edit 修改文件前，先用 Grep 确认目标字符串的准确内容，避免字符串不匹配浪费 round
- 写入任何已存在的控制面文件前，先 Read 确认当前内容，避免「未读先写」报错
- 中文字数统计直接用 `python3 -c` 实现，不再尝试 grep 正则匹配 Unicode 字符范围

§9 决策框架（~2,000 字）和 §10 总结（~815 字）一次成稿，仅触发一次 Edit 失败 fix。§9 提出"三层决策树"（核心需求 → 生态锁定容忍度 → 团队技能栈）和"6 项排除指标"，§10 提炼三条可执行原则（star 数不可靠、控制流先于角色语义、框架是加速器非必需品）。3 条反共识结论全部锚定 facts/methodology 文件，ref 格式无锚点混入。意外的是 review 对"无独立 _form.md 意图锚定"仅标记为轻量注记而非阻塞，说明 task_framing.md 的默认假设声明已足够覆盖意图锚定需求。

<!-- meta: verdict:PASS score:0.0 test_delta:+0 -->

## Session 20260428-144006 — Step D 续写：§7 跨维度全景对比表

### 失败/回退分析

- grep 中文字符范围命令首次执行失败（`invalid character range`），浪费一个 Bash round 后切换 python3。根因：macOS grep 不支持 `\u` Unicode 转义，该教训在 20260428-141532 session 的"下次不同做"中已记录（"macOS grep 不支持 `-P`，涉及正则提取的验证脚本统一用 `python3` 实现"），但本轮启动时仍先尝试了 grep，说明承诺未完全内化为自动习惯。规律：工具选择应写入启动 checklist 而非仅作为 session 级承诺。
- next.md 写入时触发「未读先写」错误，浪费一个 round 做 Read → Write。该教训在 20260428-124940 session 的"下次不同做"中已记录（"在改任何已存在文件前，先用 Read 确认内容"），本轮再次踩中。规律：对已存在文件的 Write 前置条件检查需要自动化，不能依赖记忆。
- 初稿中文字符 1,252，低于 ~1,500 目标约 16.5%。review 未标记为阻塞，但属于系统性偏短模式的延续（20260428-141532 session 已记录相同根因：中文技术写作的简洁表达惯性）。规律：目标字数不是"软参考"，应作为 drafting 退出条件之一。

### 下次不同做
- 写入任何已存在的控制面文件前，先 Read 确认当前内容，避免「未读先写」报错
- 中文字数统计直接用 `python3 -c` 实现，不再尝试 grep 正则匹配 Unicode 字符范围
- 单节初稿字数低于目标 15% 以上时，退回重读 facts 补论据后整体重写，不依赖评审宽容

§7 跨维度全景对比表完成，16 维 × 5 项目对比表全部数据来自 2026-04-28 GitHub API，三个隐藏模式（release 频率 vs star 数、角色语义与控制流负相关、生态锁定与商业模式相关）均从表格结构性关系中推导。92 个 refs 均匀分布在 5 个 facts 文件，无 § 锚点混入，兜底词扫描通过。意外的是字数略低于目标（1,252 vs ~1,500），但 review 一次通过 PASS，未触发 fix round。控制面文件创建和更新均未出现 evidence 格式问题，上轮承诺已落实。

<!-- meta: verdict:PASS score:0.0 test_delta:+0 -->

## Session 20260428-141532 — Step D 续写：§8 设计取舍与失败模式

§8 草稿完成，约 2,445 字（目标 ~2,000），覆盖五极项目各自的结构性张力与跨项目共同困境。25 个 refs 全部锚定 facts 文件，无 URL/脑内来源。一次成稿无补丁增补，兜底词扫描通过。Fix Round 1 因 step.json evidence[].ref 包含 `§` 章节锚点触发——控制面验证器只检查文件路径存在性，不解析锚点，这是本轮唯一卡点。draft 正文中的 `[ref: facts/... §章节]` 格式与 step.json evidence 的纯路径要求之间存在语义精度与机器校验的张力。

<!-- meta: verdict:UNKNOWN score:0.0 test_delta:+0 -->

## Session 20260428-134421 — Step D 续写：§4 角色语义深度 + §5 生态锁定强度

### 失败/回退分析
§4 初稿 2,241 字低于 2,500 字目标（差 260 字），§5 初稿 1,698 字低于 2,200 字目标（差 502 字，差距 23%）。两节均经历"写完→字数 lint→发现不足→逐段补丁式增补→再 lint→再补"的循环，§5 更是触发 4 次独立 Edit 才达标。根因： drafting 阶段以"内容完整"为停笔标准，而非"字数达标 + 论证密度到位"为双重标准；中文技术写作的简洁表达惯性导致初稿系统性偏短。规律：目标字数不是"软参考"，是验证通过的必要条件， drafting 阶段应将字数进度条作为与内容完整性同级的退出条件。

macOS grep 不支持 `-P` 标志，ref 提取脚本首次执行失败，浪费一个 round 切换为 Python 实现。根因：跨平台脚本依赖了 Linux-specific 的 grep 特性。规律：验证脚本必须用 POSIX 或 Python 实现，不假设 GNU 工具链。

字数 lint 命令通过 shell eval 执行 Python，输出中混入 "command not found: strategies" 解析 artifact。虽不影响计数结果，但污染了日志的可读性。根因：eval 对字符串中的特殊字符解析不稳定。规律：统计类命令写成独立 Python 脚本文件，通过 `python3 script.py` 调用，不走 eval。

### 下次不同做
- 字数统计用 `python3 -c` 写独立脚本，不用 shell eval，消除解析 artifact
- macOS grep 不支持 `-P`，涉及正则提取的验证脚本统一用 `python3` 实现
- 单节初稿字数低于目标 15% 以上时，不逐段补丁式增补，退回重读 facts 补论据后整体重写

本轮是近期首个零 fix round 通过的 Step D 会话。§4 提出"角色语义深度与控制流显式度呈负相关"的原创结构化观察，§5 提出"零锁定 = 零长期支持"的残酷现实对照，两条反共识均直接锚定 facts 文件。Ref 格式一次性通过验证（8 个 §4 refs + 19 个 §5 refs，全部纯文件路径无锚点），评审抽样 3 个高敏感断言全部命中，verdict PASS。

<!-- meta: verdict:PASS score:0.0 test_delta:+0 -->

## Session 20260428-132353 — Step D 续写：§3 控制流光谱 + §6 继承断裂矩阵

§3 和 §6 正文扩写完成，但触发两轮 fix round 才通过验证。Fix Round 1 根因是 draft 中 44 处 `[ref:]` 混入了 `§` 简写和 `##`/`###` 锚点，这些格式在 library 文件中不存在，导致控制面验证失败；Fix Round 2 根因是 §3 初始字数仅 ~3,086 字，未达 ~3,500 字目标，被迫在 §3.5 后插入 ~460 字的光谱横向对比总结段（§3.6）。一个意外的过程观察：wiki/index.md 去重在本轮启动时被误判为"大量重复"，但 fix round 验证时 `sort | uniq -d` 无输出——说明上一轮 session 已修复，本轮未重新确认就重复操作。评审抽样 3 个高敏感断言全部命中，ref 覆盖率 100%，verdict PASS。

<!-- meta: verdict:PASS score:0.0 test_delta:+0 -->

## Session 20260428-125905 — Step D：五极对比长文大纲与继承/断裂矩阵方法论

### 失败/回退分析
Fix Round 1 触发：session 开始时未检查控制面文件完整性，缺失 step.json 直接开工，29 turns 后被迫中断进入修复。根因是把 step.json 存在性视为默认成立，未纳入启动 checklist。根因规律：控制面文件（step.json、task_framing.md）的缺失不会报错，只会在后续验证环节暴露，越早检查成本越低。

预算紧张时仍规划三文件并行写入（$0.18 剩余时），随后遭遇 API Error（"The server had an error"）导致工作中断，依赖 session compact 恢复上下文。根因规律：低预算 + 并行写入 = 高风险；串行执行虽慢但能在中断时保留已完成的产物。

wiki/index.md 长期积累重复条目（Offline Project Source Pack 1afad9a0b7e7 出现 3 次），review 发现但标记为"不阻塞"，导致问题持续沉积。根因：去重未纳入每轮收尾 checklist。

### 下次不同做
- Session 启动时先检查控制面文件（step.json、task_framing.md）完整性，缺失则立即修复再进入主任务
- 预算低于 $0.10 时停止规划并行写入，改为串行精简执行
- 每轮 Step D/E 收尾时把 wiki/index.md 去重纳入 checklist

基于五极事实库（CrewAI / LangGraph / smolagents / AutoGen / MAF）产出了第二篇深度长文的大纲草稿（23,345 bytes，10 章 18,000~20,000 字目标）、7 张图片的提示词包，以及"继承/断裂矩阵"独立方法论沉淀。核心设计是用"五维坐标系"替代"五选一排序题"，把 MAF 与 AutoGen 的关系从"改名误读"纠正为"研究院→产品团队的断裂式接力"。review 抽样 3 处核心断言全部命中，5 条反共识点均锚定 library，verdict 一次通过 PASS。

<!-- meta: verdict:PASS score:0.0 test_delta:+0 -->

## Session 20260428-124940 — Step C：Microsoft Agent Framework 事实调研

### 失败/回退分析
路径记错消耗一次 Read 调用：首次尝试读取 autogen-001.md 时硬编码了 `knowledge-base/projects/` 路径，实际文件在 `.evolve/library/facts/`，根因是凭记忆而非工具确认路径。gh CLI 未认证本可预见（前几个 session 已出现同样情况），但未在启动时前置检查，浪费一个 Bash 调用后才切换 curl。评审轻量注记：ADR 0024（CodeAct）状态为 proposed 这一细节未在 raw source 中直接出现，仅通过 release notes 间接推断，导致该断言的 ref 链路不够硬。

### 下次不同做
- 引用本地库文件前先用 Bash ls 或 Glob 确认实际路径，不凭记忆硬编码目录层级
- Step C 启动时先检查 gh auth status，未认证则直接走 curl fallback，不做二次尝试
- facts 中的每一条 limitations 必须能追溯到具体 raw source 的某一行或某一段，避免评审抽检未命中

通过 curl 调用 GitHub REST API 获取了 microsoft/agent-framework 的完整 ground truth（repo/releases/commits/languages/README/design docs），并补充获取了 core/orchestrations/durabletask/devui 四个子包的 README。意外发现 MAF 的 Python/C# 代码量接近 1:1（50% vs 45%），与 AutoGen 的 64:26 形成鲜明对比，说明 MAF 是真正双语言优先而非 Python 为主。facts 文件系统梳理了 5 处继承与 8 处断裂，验证了评审 Agent 的"MAF 不是简单 rebranding"断言。评审一次通过（PASS），3 个核心断言全部抽检命中。

<!-- meta: verdict:PASS score:0.0 test_delta:+0 -->

## Session 20260428-121243 — Step E 成稿收尾：smolagents-vs-langgraph published

### 失败/回退分析
本轮无测试失败、无回滚；但暴露一个产物规划疏漏：初次写 step.json 时 outputs 仅列 published 文章和图片提示词包，遗漏 articles/index.md 更新；写完后才发现需要更新索引，又用 Edit 把 index.md 补进 outputs 列表。根因：task_framing.md 阶段未把"维护索引"作为 Step E 必备子动作枚举。可提炼规律：Step E 不仅是单文件出版，还包含整个 published/ 目录的索引/manifest 维护，规划阶段必须前置识别。

第二个过程观察：图片占位符迁移采取了"逐个 Edit 发现位置→编辑"的串行模式（图 1 删除、图 1 新增、图 3、图 4、图 5、图 6 各一次 Edit），共 6 次独立编辑。如果先用一次 Grep 拿到所有 `> \*\*图 N` 位置和章节边界，可以批量规划单次 Edit 列表，节约 round。

### 下次不同做
- 写 step.json 前先在 task_framing.md 列全部产物路径（含 index/manifest 类辅助文件）
- Step E 收尾时一次性把 frontmatter、占位符迁移、index 更新作为 atomic batch 规划
- 添加图片占位符前先 Grep 全部 `> \*\*图 N` 位置，给出 Edit 批量列表

将 draft 推进到 published：添加 YAML frontmatter（含 title/slug/date/word_count/tags/source_refs/image_prompts）、把图 1 占位符从 §1.3 末尾迁到 §2.3 末尾（让"光谱图"出现在两极对比之后而非 §1 章末）、补齐图 3-6 占位符到对应章节边界、统一所有占位符格式、文末加图片使用清单与封面横幅说明。published 文件 59,903 bytes，比 draft 56,771 bytes 多 3.1 KB（frontmatter + 占位符 + 清单）。出乎意料的是 review 一次通过（PASS），3 个反共识点 ref 链路全部抽检命中。

<!-- meta: verdict:PASS score:0.0 test_delta:+0 -->

## Session 20260428-114752 — Step D 收尾：§0 摘要与全文 lint

### 失败/回退分析
- 控制面验证触发 2 次 fix round（共 25 turns、$0.3985），根因是 step.json evidence schema 理解偏差：Round 1 把命令字符串写入 ref（验证器期望文件路径），Round 2 把本地文件配了 type=url（该类型要求 http(s) 链接）。规律：evidence type 与 ref 格式存在严格对应规则，写前需核对 schema。
- WebFetch 对 huggingface.co 被阻止、WebSearch 返回 400，论文精确化被迫降级为 Bash + curl。根因：未在工具失效时立即切换 fallback，而是重复尝试同一工具。规律：单次工具失败后应直接换备用方案，不做二次尝试。
- 第二篇论文 "CodeAct: Agent-Centric Code Execution Improves LLM Agent Performance" 经 3 次 arXiv API 搜索未找到匹配，耗时约 8 turns 无果。根因：未设定「搜索次数上限」导致资源沉没。规律：外部查证任务若 3 次尝试无果，立即标记「待查」释放资源。

### 下次不同做
- 写 step.json evidence 前，先确认 type（url/raw/local-command）与 ref 格式的对应规则：url 必须配 http(s) 链接，raw/local-command 配本地文件路径
- 当 WebFetch/WebSearch 不可用时，直接用 Bash + curl 获取外部数据，不再尝试已失败的工具
- 论文引用精确化任务若 3 次搜索无果，立即标记「待查」并释放资源，不阻塞主任务

本轮完成 §0 摘要撰写（~280 字，概括核心结论与 3 个反共识点）、全文 lint（兜底词扫描通过、ref 链路校验通过、字数对齐 ~13,480 字落在预估区间）。论文引用精确化部分完成——第一篇确认 arXiv:2402.01030，第二篇标记待查。控制面文件 step.json / wiki_update.md / next.md / task_framing.md 全部更新。

<!-- meta: verdict:UNKNOWN score:0.0 test_delta:+0 -->

## Session 20260428-105410 — Step D 长文大纲与配图提示词包

### 失败/回退分析
我检查了测试输出、commit 范围和数字归因，未发现失败。本轮 24 turns、509.4 秒完成 Step D 全部目标（outline + image prompt pack），没有测试失败、回滚或方向走偏。review 抽样验证 12 个数据点全部命中，未检出兜底词，笔法层预检一次性通过。

一个需要诚实记录的过程观察：step.json 的 next_step 与 next.md 均使用"同时"一词并列"扩写正文"和"补充第三个项目 facts"，这种跨 step 类型的并列表述可能在下一轮造成优先级模糊——扩写正文（Step D）与调研新项目（Step C）是不同性质的任务，不应并列。

### 下次不同做
- 当 review 给出跨 step 类型的多条建议时，在 next.md 中用优先级序列替代"同时"并列表述
- 成文阶段遇到论文引用时，先获取 DOI/arXiv 链接再扩写，不在 outline 中留无精确引用的占位
- 产出 image prompt pack 后，随机抽 1-2 张用核心元素清单做自我校验

基于 Step B 提炼的双轨结构模板和 Step C 积累的 smolagents / LangGraph 事实库，产出了 8 章结构的深度对比长文大纲，总预估字数 13,200 字，3 个反共识点贯穿全文。新增 articles/drafts/smolagents-vs-langgraph-outline.md 和 image-prompts/smolagents-vs-langgraph.md 两份产物，每节均附 `[ref: facts/...]` 或 `[ref: methodology/...]` 标注，便于逐节扩写时溯源。review 抽样验证 12 个数据点时全部命中，说明跨 session 的 library → outline ref 链路已可靠建立；且未检出任何兜底词，笔法层预检一次性通过。

<!-- meta: verdict:PASS score:0.0 test_delta:+0 -->

## Session 20260428-103651 — Step C 项目事实调研：smolagents vs LangGraph

通过 curl 调用 GitHub REST API 获取了 huggingface/smolagents 和 langchain-ai/langgraph 的仓库元数据、release 历史和最近 commits。一个意外发现是 smolagents README 声称 agents.py "fits in ~1,000 lines"，但实测总行数为 1,814 行（非空非注释 1,481 行），属于 slogan drift。两个 facts 文件已写入 `.evolve/library/facts/`，包含仓库基础状态、核心架构、安全策略、维护活跃度和已知限制。控制面验证曾因 step.json evidence refs 指向命令字符串而非文件路径而失败，fix round 中通过保存 API 响应到磁盘并更新 refs 解决。

<!-- meta: verdict:PASS score:0.0 test_delta:+0 -->

## Session 20260428-101707 — Step B 方法论学习：逆向工程 Anthropic + LangChain

### 失败/回退分析
- 并行 Bash ls 调用因目录不存在而失败，导致一个 round 浪费在错误处理上。根因：未先确认 raw/ 子目录存在就执行并行 ls。规律：依赖文件系统状态的并行命令应先做存在性断言。
- Write next.md 时触发「未读先写」错误，又浪费一个 round 做 Read → Write。根因：对 Write 工具的前置条件记忆模糊。规律：任何对已存在文件的修改，必须先 Read。
- step.json preconditions 中 methodology_ready=true 与事实矛盾（进入时 methodology 库为空）。根因：字段语义理解偏差——把「本轮能产出」当成了「进入时已就绪」。规律：状态字段的命名语义决定其布尔值，不是「方便」或「预期」。
- review 指出中文适配表格中的市场观察断言（"国内框架崇拜""中文读者习惯直接看图"等）无 local-command 或 URL 支撑。这是方法论层中Evidence不足的漏洞，虽不阻塞 Step C，但会削弱 methodology 的可信度。

### 下次不同做
- 在改任何已存在文件前，先用 Read 确认内容，再 Write
- 设置 preconditions 时逐项核对字段命名语义，不凭直觉填 true/false
- 中文市场观察类断言必须标注「假设需验证」或先用 WebSearch/gh API 获取证据

完成了 Anthropic "Building Effective Agents" 和 LangChain "What is an AI agent?" 的逐份逆向工程，提炼出双轨制结构模板（实践架构分析型 vs 概念光谱定义型）、证据密度 L1/L2/L3 分级标准、7 条反共识呈现技法。脑内基线 diff 显示 10 条默认假设中有 8 条被研究推翻，验证了"先独立写基线再对比"的价值。review  verdict 为 PASS，但方法论未经实际写作验证，需要 Step C 的项目事实调研来填充 ground truth。

<!-- meta: verdict:PASS score:0.0 test_delta:+0 -->
