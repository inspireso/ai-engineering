---
name: release
description: 发布流程 - 合并代码、记录测试通过、记录发布内容
---

# Release Command

执行发布流程：

1. 确认所有测试通过
2. 确认 review 完成
3. 主分支合并到当前分支
4. 再次确认所有测试通过
5. 确认 review 完成
6. 修改 CHANGELOG.md 文件，记录发布内容
7. 按照 git 提交规范提交所有变更到本地仓库

## 使用

```
/release [target]
```

target 可选：staging, production