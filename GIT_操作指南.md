# 本仓库 Git 操作指南

适用于项目目录：`myblog`（Hugo 博客）。远程仓库一般为 `origin`，主分支为 `main`。

---

## 一、进入项目目录

```bash
cd /Users/jiangweiyang/Dropbox/3-blog/myblog
```

（若已在项目根目录可跳过。）

---

## 二、从 GitHub 拉取最新（git pull）

在本地修改前或多人协作时，先同步远程改动到本机：

```bash
git pull origin main
```

若当前分支已跟踪 `origin/main`，可简写：

```bash
git pull
```

---

## 三、推送到 GitHub（git push）

把本地提交备份/发布到 GitHub：

```bash
# 1. 查看有改动的文件
git status

# 2. 添加要提交的文件（全部）
git add .

# 3. 提交（写清说明）
git commit -m "简短说明，例如：更新学习宣言、修复排版"

# 4. 推送到远程 main 分支
git push origin main
```

若当前分支已跟踪 `origin/main`，第 4 步可简写：

```bash
git push
```

---

## 四、常用组合

| 目的           | 命令 |
|----------------|------|
| 先同步再推送   | `git pull origin main` → 改文件 → `git add .` → `git commit -m "..."` → `git push origin main` |
| 只拉取不修改   | `git pull origin main` |
| 只推送不拉取   | `git add .` → `git commit -m "..."` → `git push origin main` |

---

## 五、检查远程与分支

```bash
# 查看远程仓库地址
git remote -v

# 查看当前分支
git branch
```

---

## 六、注意

- 推送前建议先 `git status` 确认要提交的内容。
- 若 `git pull` 提示有冲突，需要先解决冲突再 `git add`、`commit`、`push`。
- 使用 `publish.sh` 或 `pubpost` 发布文章时，内部已包含 `add` / `commit` / `push`，无需再单独执行一套完整流程（除非你还改了其他未纳入脚本的文件）。
