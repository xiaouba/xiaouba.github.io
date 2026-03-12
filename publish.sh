#!/usr/bin/env bash

set -euo pipefail

CHECK_ONLY=false
NO_PUSH=false
COMMIT_MSG=""
TARGET_FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --check)
      CHECK_ONLY=true
      shift
      ;;
    --no-push)
      NO_PUSH=true
      shift
      ;;
    --file)
      if [[ $# -lt 2 ]]; then
        echo "用法错误：--file 需要传入文件路径"
        exit 1
      fi
      TARGET_FILE="$2"
      shift 2
      ;;
    *)
      if [[ -z "$COMMIT_MSG" ]]; then
        COMMIT_MSG="$1"
      else
        COMMIT_MSG="$COMMIT_MSG $1"
      fi
      shift
      ;;
  esac
done

COMMIT_MSG="${COMMIT_MSG:-publish: update posts}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_ROOT"

declare -a CHECK_FILES=()
declare -a ADD_FILES=()

if [[ -n "$TARGET_FILE" ]]; then
  CHECK_FILES+=("$TARGET_FILE")
  ADD_FILES+=("$TARGET_FILE")
else
  while IFS= read -r f; do
    [[ -n "$f" ]] && CHECK_FILES+=("$f")
  done < <(git diff --name-only --diff-filter=AM -- 'content/posts/*.md')

  while IFS= read -r f; do
    [[ -n "$f" ]] && CHECK_FILES+=("$f")
  done < <(git diff --name-only --cached --diff-filter=AM -- 'content/posts/*.md')

  while IFS= read -r f; do
    [[ -n "$f" ]] && CHECK_FILES+=("$f")
  done < <(git ls-files --others --exclude-standard -- 'content/posts/*.md')

  if [[ ${#CHECK_FILES[@]} -eq 0 ]]; then
    while IFS= read -r f; do
      [[ -n "$f" ]] && CHECK_FILES+=("$f")
    done < <(git ls-files -- 'content/posts/*.md')
  fi

  if [[ ${#CHECK_FILES[@]} -gt 0 ]]; then
    ADD_FILES+=("${CHECK_FILES[@]}")
  fi
fi

if [[ ${#CHECK_FILES[@]} -eq 0 ]]; then
  echo "没有找到要检查的文章文件。"
  exit 1
fi

for f in "${CHECK_FILES[@]}"; do
  [[ -f "$f" ]] || { echo "文件不存在: $f"; exit 1; }
done

echo "==> 检查文章 front matter（draft/date）..."
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
        continue
    parts = text.split("---", 2)
    if len(parts) < 3:
        errors.append(f"{file}: front matter 格式不完整")
        continue

    front = parts[1]
    draft = None
    date_value = None
    for line in front.splitlines():
        line = line.strip()
        if line.startswith("draft:"):
            draft = line.split(":", 1)[1].strip().lower()
        elif line.startswith("date:"):
            date_value = line.split(":", 1)[1].strip()

    if draft in {"true", "yes"}:
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
    print("\n发布检查失败：")
    for item in errors:
        print(f"- {item}")
    sys.exit(2)

print("front matter 检查通过。")
PY

if [[ "$CHECK_ONLY" == "true" ]]; then
  echo "==> --check 模式：仅检查，不构建/不提交。"
  exit 0
fi

echo "==> 构建站点..."
hugo --gc --minify

echo "==> 提交并推送..."
for f in "${ADD_FILES[@]}"; do
  git add "$f"
done

if git diff --cached --quiet; then
  echo "没有可提交变更（可能你还没修改文件）。"
  exit 0
fi

git commit -m "$COMMIT_MSG"

if [[ "$NO_PUSH" == "true" ]]; then
  echo "==> --no-push 模式：已提交但未推送。"
  exit 0
fi

git push origin main

echo "==> 发布流程完成。请到 GitHub Actions 查看构建状态。"
