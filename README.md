# Godogen - GitHub 集成说明

## 自动提交配置

### 工作流程

1. 修改代码后告诉我："提交代码" 或 "git commit"
2. 我会自动：
   - 分析修改的文件和内容
   - 生成规范的 commit message
   - 推送到 GitHub

### Commit Message 格式

```
🚀 [模块名] 更新

📅 时间: YYYY-MM-DD HH:MM
📁 修改文件:
   - file1.gd
   - file2.tscn
   
📝 改动说明:
   • 具体改动内容

🤖 自动生成 by 龙虾大人
```

### 示例

```
🚀 Tower 更新

📅 时间: 2026-03-21 16:00
📁 修改文件:
   - scripts/tower.gd
   - scenes/tower.tscn

📝 改动说明:
   • 添加箭塔攻击范围显示
   • 修复敌人移动路径bug

🤖 自动生成 by 龙虾大人
```

## 仓库信息

- 地址: https://github.com/flywxiang/godogen
- 账号: flywxiang
- Token: 已配置

## 常用 Git 命令

```bash
# 查看状态
git status

# 查看修改
git diff

# 添加修改
git add .

# 提交（自动生成信息）
git commit -m "描述"

# 推送
git push
```
