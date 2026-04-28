**适用场景**: 全文草稿（sec0-secN）完成撰写后，进入成稿前的整稿 lint 与格式统一阶段

**步骤**:
1. 检查控制面文件完整性：step.json、task_framing.md 必须存在且内容非空
2. § 锚点扫描：`rg '\[ref: .*[§#]' articles/drafts/*sec*.md` 必须无匹配
3. duplicate ref 扫描：`rg '\[ref: ([^\]]+)\] \[ref: \1\]' articles/drafts/*sec*.md` 必须无匹配
4. image placeholder 一致性：所有 `> **图 N 插入位置**` 格式统一为 `详见 \`image-prompts/SLUG.md\` 图 N`
5. 图号对齐：grep 所有 `图 N 插入位置`，确认 N 在 image-prompts 包中存在
6. 章节衔接语扫描：grep `前五节` `前四节` 等序数词，确认与实际章节数一致
7. outline 对齐：对比 outline 的章节列表与 draft 文件列表
8. 字数统计：`python3 -c "import glob, re; ..."` 统计中文字符数，确认在目标区间
9. 兜底词扫描：`rg '通常|一般来说|大家都知道|众所周知|显然|大概|默认' articles/drafts/*sec*.md`

**注意事项**:
- 以上所有验证脚本统一用 python3 实现，不用 macOS grep 做 Unicode 匹配
- 对同一文件的修改，全程使用同一工具（要么全用 Edit，要么全用 sed），禁止混用
- 控制面文件检查必须是步骤 1，不能后置
