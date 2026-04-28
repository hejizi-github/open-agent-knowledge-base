#!/usr/bin/env bash
# 文章草稿 lint 工具：字数统计、兜底词扫描、ref 格式检查

set -euo pipefail

FILE="${1:-}"
if [[ -z "$FILE" ]]; then
    echo "Usage: $0 <draft.md>"
    exit 1
fi

echo "=== Lint: $FILE ==="

# 中文字数统计（python3，避免 macOS grep 不支持 Unicode）
python3 -c "
import re, sys
with open('$FILE') as f:
    text = f.read()
chars = len(re.findall(r'[一-鿿]', text))
print(f'Chinese characters: {chars}')
"

# 兜底词扫描（列表维护在脚本内，避免依赖外部配置）
python3 -c "
hedge = ['通常', '一般来说', '一般', '大概', '应该', '显然', '众所周知', '大家都知道']
with open('$FILE') as f:
    lines = f.readlines()
found = False
for i, line in enumerate(lines, 1):
    for w in hedge:
        if w in line:
            print(f'  FOUND hedge word at line {i}: {w}')
            found = True
if not found:
    print('  OK: no hedge words')
"

# §/# 锚点混入 ref 检查
bad_refs=$(grep -nE '\[ref:[^]]+§[^]]*\]' "$FILE" || true)
if [[ -n "$bad_refs" ]]; then
    echo "WARNING: refs with §/# anchors:"
    echo "$bad_refs"
    count=$(echo "$bad_refs" | grep -c '' || true)
    echo "  count: $count"
else
    echo "OK: no refs with §/# anchors"
fi

# 同行重复 ref 检查（同一行同一 ref 出现多次）
# 使用 python3 避免 macOS 默认 awk 不支持 match() 第三参数捕获组的问题
python3 -c "
import re, sys
with open('$FILE') as f:
    lines = f.readlines()
found = False
for i, line in enumerate(lines, 1):
    refs = re.findall(r'\[ref:[^\]]+\]', line)
    seen = {}
    for r in refs:
        if r in seen:
            print(f'  {i}: dup ref: {r}')
            found = True
        else:
            seen[r] = True
if not found:
    print('OK: no duplicate refs on same line')
"
