**适用场景**: 在 open-agent-knowledge-base 项目中，基于已有 outline 和 facts 库撰写新章节草稿时

**步骤**:
1. 读取 outline 和最近已写章节，确认当前章节在全文中的位置、与前后章节的衔接关系、文风基调
2. 读取本章依赖的 facts 文件，验证关键数据（版本号、代码量、star 数等）的准确性
3. 创建/更新控制面文件：task_framing.md（本章任务框定）和 step.json（step 选择 + preconditions + evidence）
4. 写草稿：先写章节标题和子结构，再逐段填充，每段关键断言后紧跟 `[ref: facts/xxx-001.md]`
5. 验证：a) 字数统计（python3 -c）b) 兜底词扫描 c) ref 格式检查（无 §/## 锚点混入）
6. 更新控制面文件：wiki_update.md（知识沉淀候选）和 next.md（下一轮建议）

**注意事项**:
- 已存在的控制面文件必须先 Read 再 Write
- 字数统计必须用 python3，macOS grep 不支持 Unicode 字符范围正则
- step.json evidence[].ref 必须是纯文件路径，不能有 § 锚点字符
- 初稿字数低于目标 15% 以上时不补丁式增补，应退回补论据后整体重写
