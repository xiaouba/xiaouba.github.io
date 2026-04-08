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

# Windows check-only flow
.\publish.ps1 -Check -File "content/posts/文章名.md"

# Windows validate + build flow
.\publish.ps1 -File "content/posts/文章名.md"

# Check front matter only
./publish.sh --check --file "content/posts/文章名.md"

# Validate a post and run a local production build
./publish.sh --file "content/posts/文章名.md"

# Windows helper for creating a post
.\new.ps1 文章名
```

## Architecture

- **Config**: `hugo.yaml` — site settings, menu, theme params, permalink pattern (`/:year/:month/:contentbasename/`)
- **Content**: `content/posts/*.md` — blog posts; `content/about/index.md` — about page
- **Archetypes**: `archetypes/posts.md` — template for `hugo new posts/...`, generates front matter with `draft: true`
- **Theme**: PaperMod via git submodule — do not edit files in `themes/PaperMod/` directly
- **CI/CD**: `.github/workflows/deploy-to-branch.yml` — on push to main, builds Hugo and deploys to `gh-pages` branch
- **Publish scripts**: `publish.sh` and `publish.ps1` — validate post front matter and run a local production build; Git commits and pushes are manual

## Post Front Matter Requirements

Posts must have YAML front matter with at minimum: `title`, `date`, `draft`. The publish script enforces:
- `draft` must be `false` (not `true`) to publish
- `date` must not be in the future
- `date` must be parseable ISO format

## Publishing Workflow

1. Create or edit content under `content/posts/`
2. On Windows, run `.\publish.ps1 -Check -File "content/posts/文章名.md"` for a fast validation pass
3. On Windows, run `.\publish.ps1 -File "content/posts/文章名.md"` before release
4. On Bash environments, use the equivalent `./publish.sh` commands
5. Review `git status`, stage all required files, then commit and push manually

## Language

Site language is Chinese (`zh-cn`). Content, commit messages, and UI are in Chinese. `hasCJKLanguage: true` is set for proper word count/reading time.
