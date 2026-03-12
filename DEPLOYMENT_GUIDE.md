# GitHub Pages 部署指南

## 步骤一：创建 GitHub 仓库

1. 登录你的 GitHub 账号
2. 创建一个新仓库，仓库名必须是：`yourusername.github.io`
   - 例如：如果你的用户名是 `john`，仓库名应该是 `john.github.io`
3. 不要初始化 README、.gitignore 或 LICENSE

## 步骤二：更新配置

1. 编辑 `hugo.yaml` 文件：
   - 将 `baseURL` 改为：`https://yourusername.github.io/`
   - 更新 `author` 为你的名字
   - 更新社交链接

2. 编辑 `content/about/index.md`：
   - 更新个人信息

## 步骤三：推送到 GitHub

在 myblog 目录下执行：

```bash
# 添加所有文件
git add .

# 提交
git commit -m "Initial commit"

# 添加远程仓库（替换为你的仓库地址）
git remote add origin https://github.com/yourusername/yourusername.github.io.git

# 推送到 main 分支
git branch -M main
git push -u origin main
```

## 步骤四：配置 GitHub Pages

1. 进入仓库的 Settings 页面
2. 找到左侧菜单的 "Pages" 选项
3. 在 "Source" 下选择 "GitHub Actions"
4. 等待几分钟，Actions 自动构建完成

## 步骤五：访问网站

访问 `https://yourusername.github.io` 查看你的博客！

## 后续写文章

### 1. 创建新文章

创建文件 `content/posts/新文章名.md`：

```markdown
---
title: "文章标题"
date: 2025-09-21T10:00:00+08:00
draft: false
tags: ["标签1", "标签2"]
categories: ["分类"]
description: "文章描述"
---

文章内容...
```

### 2. 本地预览

```bash
hugo server
```

访问 http://localhost:1313 预览

### 3. 发布文章

```bash
git add .
git commit -m "Add new post: 文章标题"
git push
```

推送后 GitHub Actions 会自动部署。

### 4. 高效发布（推荐）

为避免发布时遗漏 `draft` 或未来时间，项目已增加自动发布脚本 `publish.sh`，并支持 `pubpost` 一键命令。

#### 4.1 自动发布脚本（`publish.sh`）

脚本能力：

- 自动检查文章 front matter 中的 `draft` 和 `date`
- 检查通过后自动执行：构建 -> 提交 -> 推送
- 支持只检查、不推送、按单篇发布

常用用法：

```bash
# 仅检查某一篇文章（不构建、不提交）
./publish.sh --check --file "content/posts/文章名.md"

# 发布某一篇文章（检查 + 构建 + commit + push）
./publish.sh --file "content/posts/文章名.md" "publish: 文章标题"

# 检查 + 构建 + 提交，但不推送
./publish.sh --no-push --file "content/posts/文章名.md" "publish: 文章标题"
```

> 注意：如果你不传 `--file`，脚本会优先检查当前改动的文章；若没有改动，再回退检查全部文章。存在其他 `draft: true` 草稿时，可能会阻止发布。

#### 4.2 一键发布命令（`pubpost`）

已在 `~/.zshrc` 中配置函数 `pubpost`，本质上调用 `publish.sh`：

```bash
pubpost "content/posts/文章名.md" "publish: 文章标题"
```

若不传提交信息，会使用默认提交信息：

```bash
pubpost "content/posts/文章名.md"
```

首次使用或修改 `~/.zshrc` 后，执行：

```bash
source ~/.zshrc
```

#### 4.3 发布前最小检查清单

- `draft: false`
- `date` 不是未来时间
- 目标分支是 `main`
- 本地预览正常（可选）

```bash
hugo server
```

### 5. GitHub 备份

项目已是 Git 仓库，备份即把本地提交推送到 GitHub 远程。

#### 5.1 确认远程

在项目根目录执行：

```bash
git remote -v
```

若有 `origin` 指向你的 GitHub 仓库地址（如 `https://github.com/xiaouba/xiaouba.github.io.git`），说明已连接。

#### 5.2 日常备份（推送到 GitHub）

改完文章或配置后：

```bash
git add .
git status                    # 确认要提交的内容
git commit -m "备份: 简短说明"
git push origin main
```

主仓库即你的在线备份。

#### 5.3 双份备份：增加第二个远程

若希望除主仓库外再有一个纯备份仓库（如 `myblog-backup`）：

1. 在 GitHub 新建空仓库，例如 `myblog-backup`（不勾选初始化 README）。
2. 本地添加备份远程并推送：

```bash
git remote add backup https://github.com/你的用户名/myblog-backup.git
git push -u backup main
```

之后每次可同时推两个远程：

```bash
git push origin main
git push backup main
```

#### 5.4 与发布流程的关系

使用 `publish.sh` 或 `pubpost` 发布时，其内部会执行 `git add`、`commit`、`push origin main`，因此**每次成功发布到 GitHub Pages 的同时，也完成了一次 GitHub 备份**。

---

## 生成定制格式的 .md 文档

Hugo 通过 **Archetypes（原型）** 控制 `hugo new` 生成的文章 front matter 结构。你可以用默认原型，也可以自定义多种原型来生成不同用途的 .md 文档。

### 1. 使用默认原型生成文章

当前项目在 `archetypes/posts.md` 中定义了文章模板，执行：

```bash
hugo new posts/我的新文章.md
```

会在 `content/posts/` 下生成一篇带默认 front matter 的草稿，例如：

```yaml
---
title: "我的新文章"
date: 2025-03-09T...
draft: true
author: "xiaouba"
categories: []
tags: []
description: ""
slug: ""
---
```

生成后直接在该文件里写正文即可。

### 2. 自定义原型模板

在 `archetypes/` 目录下新增或修改 `.md` 文件即可定义新的“格式”：

- **文件名** = 内容类型（对应 `hugo new <类型>/文件名.md` 的 `<类型>`）
- **文件内容** = 该类型文档的 front matter 模板，支持 Hugo 模板语法

**示例：新增「笔记」类型**

1. 新建 `archetypes/notes.md`：

```yaml
---
title: "{{ replace .Name "-" " " | title }}"
date: {{ .Date }}
draft: true
type: note
tags: []
---
```

2. 生成笔记文档：

```bash
hugo new notes/某条笔记.md
```

会在 `content/notes/某条笔记.md` 生成使用该模板的 .md（如主题支持 `notes` 类型，会按笔记样式展示）。

**示例：定制文章原型**

编辑 `archetypes/posts.md`，可增删或改 front matter 字段，例如增加 `series`、`toc` 等。保存后，之后所有 `hugo new posts/xxx.md` 都会按新模板生成。

### 3. 常用模板变量

在原型里可用的变量包括：

| 变量 | 说明 |
|------|------|
| `{{ .Name }}` | 文件名（不含扩展名），如 `my-post` |
| `{{ .Date }}` | 当前时间，ISO 格式 |
| `replace .Name "-" " " \| title` | 将文件名中的 `-` 换成空格并首字母大写，作为标题 |

可按需组合，做出不同风格的标题、日期、默认标签等。

### 4. 不通过 Hugo 时的手动格式

若不使用 `hugo new`，也可以直接新建 `content/posts/xxx.md`，按 PaperMod 和 `hugo.yaml` 要求手写 front matter，例如：

```markdown
---
title: "自定义标题"
date: 2025-03-09T12:00:00+08:00
draft: false
tags: ["标签1", "标签2"]
categories: ["分类"]
description: "简短描述"
---
正文...
```

只要 front matter 符合主题要求，Hugo 会正常解析并渲染。

---

## 常见问题

### Q: 网站没有更新？
A: 检查 Actions 页面是否构建成功，通常需要等待 2-3 分钟。

### Q: 如何修改主题样式？
A: 可以在 `hugo.yaml` 的 `params` 部分进行配置。

### Q: 如何添加评论功能？
A: 可以集成 Disqus、Giscus 等评论系统。

## 有用的命令

```bash
# 本地预览（包括草稿）
hugo server -D

# 构建网站
hugo

# 创建新文章
hugo new posts/文章名.md

# 查看 Hugo 版本
hugo version
```