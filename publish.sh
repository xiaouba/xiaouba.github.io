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
declare -a VALIDATION_ERRORS=()

trim_value() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  value="${value%\"}"
  value="${value#\"}"
  value="${value%\'}"
  value="${value#\'}"
  printf '%s' "$value"
}

extract_front_matter_value() {
  local file="$1"
  local key="$2"

  awk -v wanted_key="$key" '
    BEGIN { in_front = 0 }
    NR == 1 && $0 == "---" { in_front = 1; next }
    in_front && $0 == "---" { exit }
    in_front {
      pos = index($0, ":")
      if (pos > 0) {
        current_key = substr($0, 1, pos - 1)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", current_key)
        if (current_key == wanted_key) {
          print substr($0, pos + 1)
          exit
        }
      }
    }
  ' "$file"
}

validate_file() {
  local file="$1"
  local title draft raw_date date_epoch now_epoch

  if ! head -n 1 "$file" | grep -qx -- '---'; then
    VALIDATION_ERRORS+=("$file: 缺少 YAML front matter")
    return
  fi

  if ! awk 'BEGIN { count = 0 } $0 == "---" { count++ } END { exit(count >= 2 ? 0 : 1) }' "$file"; then
    VALIDATION_ERRORS+=("$file: front matter 格式不完整")
    return
  fi

  title="$(trim_value "$(extract_front_matter_value "$file" "title")")"
  draft="$(trim_value "$(extract_front_matter_value "$file" "draft")")"
  raw_date="$(trim_value "$(extract_front_matter_value "$file" "date")")"

  if [[ -z "$title" ]]; then
    VALIDATION_ERRORS+=("$file: 缺少 title 字段")
  fi

  if [[ -z "$draft" ]]; then
    VALIDATION_ERRORS+=("$file: 缺少 draft 字段")
  else
    case "${draft,,}" in
      true|yes)
        VALIDATION_ERRORS+=("$file: draft=true，不能发布")
        ;;
    esac
  fi

  if [[ -z "$raw_date" ]]; then
    VALIDATION_ERRORS+=("$file: 缺少 date 字段")
    return
  fi

  raw_date="${raw_date/Z/+00:00}"
  if ! date_epoch="$(date -d "$raw_date" +%s 2>/dev/null)"; then
    VALIDATION_ERRORS+=("$file: date 无法解析（$raw_date）")
    return
  fi

  now_epoch="$(date +%s)"
  if (( date_epoch > now_epoch )); then
    VALIDATION_ERRORS+=("$file: date 是未来时间（$raw_date）")
  fi
}

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
for f in "${CHECK_FILES[@]}"; do
  validate_file "$f"
done

if [[ ${#VALIDATION_ERRORS[@]} -gt 0 ]]; then
  printf '\n检查失败：\n'
  for err in "${VALIDATION_ERRORS[@]}"; do
    printf -- '- %s\n' "$err"
  done
  exit 2
fi

echo "front matter 检查通过。"

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
