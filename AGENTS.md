# Repository Guidelines

## Project Structure & Module Organization
This repository is a Hugo blog. Main content lives in `content/`, with posts in `content/posts/` and the About page in `content/about/index.md`. Site configuration is in `hugo.yaml`, and new post templates come from `archetypes/posts.md`. Static assets belong in `static/`; Hugo-generated output is written to `public/` and should be treated as build output. The PaperMod theme is vendored as a Git submodule in `themes/PaperMod/`; prefer overriding layouts or assets in the root project rather than editing the submodule directly.

## Build, Test, and Development Commands
Use Hugo Extended locally.

- `hugo server -D`: run a local preview including drafts at `http://localhost:1313`
- `hugo server`: preview only published content
- `hugo --gc --minify`: production build with cleanup and minification
- `hugo new posts/my-post.md`: create a new post from `archetypes/posts.md`
- `.\publish.ps1 -Check -File "content/posts/文章名.md"`: validate front matter before publishing on Windows
- `.\publish.ps1 -File "content/posts/文章名.md"`: validate the post and run a local production build on Windows
- `./publish.sh --check --file "content/posts/文章名.md"`: validate front matter before publishing
- `./publish.sh --file "content/posts/文章名.md"`: validate the post and run a local production build
- `.\new.ps1 文章名`: Windows helper for creating `content/posts/文章名.md`

## Coding Style & Naming Conventions
Write content and UI copy in Chinese unless a file clearly requires English. Use YAML front matter with concise, lowercase keys such as `title`, `date`, `draft`, `tags`, and `categories`. Keep Markdown readable with short paragraphs and fenced code blocks. Post filenames should be kebab-case or descriptive Chinese titles, for example `book-reading-2603-活法.md`. Do not hand-edit files under `public/`.

## Testing Guidelines
There is no formal test suite in this repository. Validation is build-based: run `hugo --gc --minify` before opening a PR, and use `publish.sh --check` for post-level checks. Posts must have valid YAML front matter, `draft: false` before publishing, and a `date` that is not in the future.

## Commit & Pull Request Guidelines
Recent history follows short, purpose-first commit messages such as `publish: update post`, `fix: update PaperMod submodule to valid commit`, or Chinese summaries like `更新配置与内容...`. Keep commits focused and use the `publish:` prefix for content releases when appropriate. PRs should include a brief description, affected paths, linked issue if applicable, and screenshots only when UI or theme output changes.

## Contributor Notes
Treat `themes/PaperMod/` as external code. For site behavior changes, prefer project-level overrides in `layouts/`, `static/`, or `hugo.yaml`. `publish.sh` and `publish.ps1` no longer commit or push, so always review `git status` and stage all required files manually before publishing. If you change deployment behavior, also review `.github/workflows/`.
