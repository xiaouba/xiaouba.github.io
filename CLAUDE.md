# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Chinese personal blog (小藕霸霸的烂笔头) built with Hugo static site generator, using the PaperMod theme (git submodule at `themes/PaperMod`). Deployed to GitHub Pages at https://xiaouba.github.io/ via GitHub Actions.

## Key Commands

```bash
# Local preview (including drafts)
hugo server -D

# Local preview (published posts only)
hugo server

# Build site
hugo --gc --minify

# Create new post (generates from archetypes/posts.md template)
hugo new posts/文章名.md

# Publish a post (checks front matter, builds, commits, pushes)
./publish.sh --file "content/posts/文章名.md" "publish: 文章标题"

# Check front matter only (no build/commit)
./publish.sh --check --file "content/posts/文章名.md"

# Publish without pushing to remote
./publish.sh --no-push --file "content/posts/文章名.md" "publish: 文章标题"
```

## Architecture

- **Config**: `hugo.yaml` — site settings, menu, theme params, permalink pattern (`/:year/:month/:contentbasename/`)
- **Content**: `content/posts/*.md` — blog posts; `content/about/index.md` — about page
- **Archetypes**: `archetypes/posts.md` — template for `hugo new posts/...`, generates front matter with `draft: true`
- **Theme**: PaperMod via git submodule — do not edit files in `themes/PaperMod/` directly
- **CI/CD**: `.github/workflows/deploy-to-branch.yml` — on push to main, builds Hugo and deploys to `gh-pages` branch
- **Publish script**: `publish.sh` — validates front matter (draft status, date not in future), builds, commits, and pushes

## Post Front Matter Requirements

Posts must have YAML front matter with at minimum: `title`, `date`, `draft`. The publish script enforces:
- `draft` must be `false` (not `true`) to publish
- `date` must not be in the future
- `date` must be parseable ISO format

## Language

Site language is Chinese (`zh-cn`). Content, commit messages, and UI are in Chinese. `hasCJKLanguage: true` is set for proper word count/reading time.
