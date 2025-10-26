# 我的个人博客

这是我的个人博客网站源代码，使用 Hugo 静态网站生成器构建，托管在 GitHub Pages 上。

## 技术栈

- **Hugo** - 静态网站生成器
- **PaperMod** - Hugo 主题
- **GitHub Pages** - 网站托管
- **GitHub Actions** - 自动部署

## 本地运行

1. 安装 Hugo Extended 版本
2. 克隆本仓库及子模块：
   ```bash
   git clone --recurse-submodules https://github.com/yourusername/yourusername.github.io.git
   ```
3. 本地预览：
   ```bash
   hugo server -D
   ```
4. 访问 http://localhost:1313

## 写新文章

```bash
hugo new posts/my-new-post.md
```

## 部署

推送到 main 分支后，GitHub Actions 会自动构建并部署到 GitHub Pages。

## 许可证

MIT