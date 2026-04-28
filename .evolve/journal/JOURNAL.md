# Journal

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
