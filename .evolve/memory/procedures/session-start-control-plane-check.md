**适用场景**: 每个 session 开始时，确认控制面文件完整后再进入主任务，避免中途因缺失 step.json 或 task_framing.md 触发 fix round。

**步骤**:
1. 检查 `.evolve/sessions/${SESSION_ID}.step.json` 是否存在；缺失则用 Write 创建（参照上一轮 step.json 模板）
2. 检查 `.evolve/sessions/${SESSION_ID}.task_framing.md` 是否存在；缺失则用 Write 创建（基于项目目标和当前 step 推断）
3. 检查 `.evolve/sessions/${SESSION_ID}.log` 是否存在；缺失则不影响主任务但标记 warning
4. 以上任意文件缺失时，优先修复控制面再读取 library/facts/methodology 等 ground truth

**注意事项**:
- step.json 的 evidence 字段中，type=url 必须配 http(s) 链接，type=raw/local-command 配本地文件路径
- task_framing.md 必须包含 Expert Lens、Default Assumptions 和 This Session Step 三个区块
- 不要假设上一轮 session 已正确写入所有控制面文件——外层 self-evolve 可能因 budget cut-off 提前终止
