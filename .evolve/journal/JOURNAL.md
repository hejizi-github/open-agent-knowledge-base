# Journal

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
