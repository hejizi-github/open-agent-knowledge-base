**适用场景**: 需要获取 GitHub 公开仓库的元数据、release、commits、README 等信息作为项目调研的 ground truth

**步骤**:
1. 检查 `gh` CLI 认证状态：`gh auth status` 或 `gh --version`
2. 若 `gh` 已认证，使用 `gh repo view --json` 和 `gh release list` 获取数据
3. 若 `gh` 未认证或不可用，改用 `curl -sL https://api.github.com/repos/{owner}/{repo}` 调用 GitHub REST API（公开仓库无需认证，rate limit 60 req/hr）
4. 将 API 响应保存到 `.evolve/raw/` 目录，文件名格式：`{repo}-repo-api.json`、`{repo}-release-api.json`
5. 验证保存的文件为有效 JSON：`python3 -m json.tool < file.json > /dev/null`
6. 在 step.json evidence 中引用这些文件路径作为 ref，不写命令字符串

**注意事项**:
- `gh` CLI 即使返回非零退出码，也可能输出「未认证」提示到 stdout，不要仅凭 exit code 判断成功
- curl 获取大响应（如 commits）可能超时，设置 `--max-time 30`
- 文件保存后必须用 `test -f` 确认存在，再写入 step.json evidence
