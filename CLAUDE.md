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

# Git Bash check-only flow
./publish.sh --check --file "content/posts/文章名.md"

# Git Bash validate + build flow
./publish.sh --file "content/posts/文章名.md"

# PowerShell fallback
.\publish.ps1 -Check -File "content/posts/文章名.md"
.\publish.ps1 -File "content/posts/文章名.md"
.\new.ps1 文章名
```

## Architecture

- **Config**: `hugo.yaml` — site settings, menu, theme params, permalink pattern (`/:year/:month/:contentbasename/`)
- **Content**: `content/posts/*.md` — blog posts; `content/about/index.md` — about page
- **Archetypes**: `archetypes/posts.md` — template for `hugo new posts/...`, generates front matter with `draft: true`
- **Theme**: PaperMod via git submodule — do not edit files in `themes/PaperMod/` directly
- **CI/CD**: `.github/workflows/deploy-to-branch.yml` — on push to main, builds Hugo and deploys to `gh-pages` branch
- **Publish scripts**: `publish.sh` is the primary Git Bash workflow; `publish.ps1` is a Windows fallback. Both validate front matter and run a local production build; Git commits and pushes are manual

## Post Front Matter Requirements

Posts must have YAML front matter with at minimum: `title`, `date`, `draft`. The publish script enforces:
- `draft` must be `false` (not `true`) to publish
- `date` must not be in the future
- `date` must be parseable ISO format

## Publishing Workflow

1. Create or edit content under `content/posts/`
2. In Git Bash, run `./publish.sh --check --file "content/posts/文章名.md"` for a fast validation pass
3. In Git Bash, run `./publish.sh --file "content/posts/文章名.md"` before release
4. Use `publish.ps1` only when working in PowerShell
5. Review `git status`, stage all required files, then commit and push manually

## Language

Site language is Chinese (`zh-cn`). Content, commit messages, and UI are in Chinese. `hasCJKLanguage: true` is set for proper word count/reading time.
