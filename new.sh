#!/usr/bin/env bash
# Usage: ./new.sh post-name
# Bash 版 new.ps1，供 Emacs `C-c y b`（yjw/hugo-new-post）调用：
# 在 content/posts/ 下新建文章，stdout 只打印新文件的绝对路径。
# 有 hugo 时用 `hugo new`；没有时按 archetypes/posts.md 的字段直接生成。

set -euo pipefail

if [[ $# -lt 1 || -z "$1" ]]; then
  echo "Usage: ./new.sh post-name" >&2
  exit 1
fi

cd "$(dirname "${BASH_SOURCE[0]}")"

name="$1"
rel="content/posts/${name}.md"

if [[ -e "$rel" ]]; then
  echo "文章已存在: $rel" >&2
  exit 1
fi

if command -v hugo >/dev/null 2>&1; then
  # hugo new 自己的提示信息走 stderr，保持 stdout 只有路径
  hugo new "posts/${name}.md" >&2
else
  title="${name//-/ }"
  date="$(date +%Y-%m-%dT%H:%M:%S%:z)"
  cat > "$rel" <<FM
---
title: "${title}"
date: ${date}
draft: true
author: "小藕霸霸"
categories: []
tags: []
description: ""
slug: ""
---

FM
fi

[[ -f "$rel" ]] || { echo "未生成文件: $rel" >&2; exit 1; }
printf '%s\n' "$PWD/$rel"
