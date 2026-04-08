#!/usr/bin/env bash

set -euo pipefail

CHECK_ONLY=false
TARGET_FILE=""

usage() {
  cat <<'EOF'
用法:
  ./publish.sh --check --file "content/posts/文章名.md"
  ./publish.sh --file "content/posts/文章名.md"
  ./publish.sh

说明:
  - 默认行为: 检查文章 front matter，并执行 Hugo 构建
  - --check: 仅检查，不构建
  - --file: 只检查指定文章；未指定时优先检查当前改动的文章，没有改动时回退检查全部文章

注意:
  此脚本不再执行 git add / commit / push。
  构建通过后，请手动检查并提交所有需要发布的文件。
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --check)
      CHECK_ONLY=true
      shift
      ;;
    --file)
      if [[ $# -lt 2 ]]; then
        echo "用法错误：--file 需要传入文件路径"
        usage
        exit 1
      fi
      TARGET_FILE="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "未知参数: $1"
      usage
      exit 1
      ;;
  esac
done

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_ROOT"

declare -a CHECK_FILES=()

append_unique() {
  local item
  for item in "${CHECK_FILES[@]}"; do
    [[ "$item" == "$1" ]] && return 0
  done
  CHECK_FILES+=("$1")
}

if [[ -n "$TARGET_FILE" ]]; then
  append_unique "$TARGET_FILE"
else
  while IFS= read -r f; do
    [[ -n "$f" ]] && append_unique "$f"
  done < <(git diff --name-only --diff-filter=AM -- 'content/posts/*.md')

  while IFS= read -r f; do
    [[ -n "$f" ]] && append_unique "$f"
  done < <(git diff --name-only --cached --diff-filter=AM -- 'content/posts/*.md')

  while IFS= read -r f; do
    [[ -n "$f" ]] && append_unique "$f"
  done < <(git ls-files --others --exclude-standard -- 'content/posts/*.md')

  if [[ ${#CHECK_FILES[@]} -eq 0 ]]; then
    while IFS= read -r f; do
      [[ -n "$f" ]] && append_unique "$f"
    done < <(git ls-files -- 'content/posts/*.md')
  fi
fi

if [[ ${#CHECK_FILES[@]} -eq 0 ]]; then
  echo "没有找到要检查的文章文件。"
  exit 1
fi

for f in "${CHECK_FILES[@]}"; do
  [[ -f "$f" ]] || { echo "文件不存在: $f"; exit 1; }
done

echo "==> 检查文章 front matter（title/date/draft）..."
python3 - "${CHECK_FILES[@]}" <<'PY'
from datetime import datetime
from pathlib import Path
import sys

if len(sys.argv) <= 1:
    print("没有收到待检查文件")
    sys.exit(1)

files = [Path(p) for p in sys.argv[1:]]
errors = []
now = datetime.now().astimezone()

for file in files:
    text = file.read_text(encoding="utf-8")
    if not text.startswith("---"):
        errors.append(f"{file}: 缺少 YAML front matter")
        continue

    parts = text.split("---", 2)
    if len(parts) < 3:
        errors.append(f"{file}: front matter 格式不完整")
        continue

    front = parts[1]
    title = None
    draft = None
    date_value = None

    for line in front.splitlines():
        line = line.strip()
        if line.startswith("title:"):
            title = line.split(":", 1)[1].strip()
        elif line.startswith("draft:"):
            draft = line.split(":", 1)[1].strip().lower()
        elif line.startswith("date:"):
            date_value = line.split(":", 1)[1].strip()

    if not title:
        errors.append(f"{file}: 缺少 title 字段")

    if draft in {None, ""}:
        errors.append(f"{file}: 缺少 draft 字段")
    elif draft in {"true", "yes"}:
        errors.append(f"{file}: draft=true，不能发布")

    if date_value:
        raw = date_value.strip("'\"")
        raw = raw.replace("Z", "+00:00")
        try:
            dt = datetime.fromisoformat(raw)
            if dt.tzinfo is None:
                dt = dt.replace(tzinfo=now.tzinfo)
            if dt > now:
                errors.append(f"{file}: date 是未来时间（{raw}）")
        except ValueError:
            errors.append(f"{file}: date 无法解析（{raw}）")
    else:
        errors.append(f"{file}: 缺少 date 字段")

if errors:
    print("\n检查失败：")
    for item in errors:
        print(f"- {item}")
    sys.exit(2)

print("front matter 检查通过。")
PY

if [[ "$CHECK_ONLY" == "true" ]]; then
  echo "==> --check 模式：仅检查，不构建。"
  exit 0
fi

echo "==> 构建站点..."
hugo --gc --minify

cat <<'EOF'
==> 构建完成。
后续建议流程：
1. git status
2. git add <需要提交的文件>
3. git commit -m "publish: 文章标题" 或 "fix: 简短说明"
4. git push origin main
EOF
