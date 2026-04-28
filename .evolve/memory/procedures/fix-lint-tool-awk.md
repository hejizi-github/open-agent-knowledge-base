# 修复 lint 工具跨平台 awk 兼容性问题

**适用场景**: lint-article-draft.sh 等验证脚本在 macOS 上触发 `awk: syntax error` 时

**步骤**:
1. 定位报错行：查看 lint 输出中的 `awk: syntax error at source line 1`
2. 读取脚本中对应的 awk 命令（通常是同行重复 ref 检查的 `match(..., arr)` 模式）
3. 判断是否为 GNU awk 特有语法（macOS 默认 awk 不支持 match 的第三参数捕获组）
4. 替换方案：
   - 方案 A（推荐）：将 awk 逻辑改写为 python3 脚本，用 `re.findall()` 实现同行重复 ref 检测
   - 方案 B：安装 `gawk`（`brew install gawk`），将脚本中的 `awk` 替换为 `gawk`
5. 验证修复：在 macOS 上运行 `bash lint-article-draft.sh <测试文件>`，确认无 awk 错误且输出正确

**注意事项**:
- 优先用 python3 实现而非依赖 gawk 安装——仓库不应对外部包管理器有假设
- python3 脚本中同行重复 ref 的正则：`\[ref:\s*([^\]]+)\]`，对每行用 `re.findall()` 后检查 `len(set(refs)) < len(refs)`
- 修复后需在同一文件上运行新旧两种实现，对比输出一致性
