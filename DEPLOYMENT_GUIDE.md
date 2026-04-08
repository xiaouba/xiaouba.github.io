# GitHub Pages 部署与发布指南

## 当前架构

- 仓库根目录就是博客项目目录，不再存在 `myblog/` 子目录
- 内容放在 `content/posts/` 和 `content/about/`
- 配置文件是 `hugo.yaml`
- 主题 `themes/PaperMod/` 为 Git submodule
- 推送到 `main` 后，由 `.github/workflows/deploy-to-branch.yml` 自动部署到 `gh-pages`

## 初始化与本地预览

```bash
git clone --recurse-submodules <repo-url>
cd 3-blog
hugo server -D
```

访问 `http://localhost:1313` 预览草稿和已发布内容。

## 写文章

推荐用 Hugo 原型创建：

```bash
hugo new posts/文章名.md
```

PowerShell 下也可以用备用脚本：

```powershell
.\new.ps1 文章名
```

新文章默认来自 `archetypes/posts.md`，会生成 `draft: true`。发布前至少确认：

- `title` 已填写
- `date` 可解析且不是未来时间
- `draft: false`

## 发布流程

推荐固定使用下面 4 步：

```bash
./publish.sh --check --file "content/posts/文章名.md"
./publish.sh --file "content/posts/文章名.md"
git status
git add <需要提交的文件>
git commit -m "publish: 文章标题"
git push origin main
```

说明：

- `publish.sh --check` 只检查文章 front matter
- `publish.sh --file ...` 会检查并执行 `hugo --gc --minify`
- `publish.ps1` 作为 PowerShell 备用入口保留
- 两个脚本都不再自动 `git add`、`commit` 或 `push`
- 如果本次同时改了 `hugo.yaml`、`layouts/`、`static/` 或工作流文件，必须手动一起提交

## 部署说明

推送到 `main` 分支后，GitHub Actions 会：

1. 拉取仓库和子模块
2. 用 Hugo Extended 构建站点
3. 将 `public/` 发布到 `gh-pages`

如果网页未更新，优先检查 GitHub Actions 是否成功。

## 维护建议

- 不要手动编辑 `public/`
- 尽量不要直接修改 `themes/PaperMod/`，优先用项目根目录覆盖
- 架构调整后，涉及配置或部署逻辑的更改，请先本地构建，再提交全部相关文件
