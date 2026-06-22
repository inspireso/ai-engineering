---
name: release
description: 发布流程 - 合并代码、记录测试通过、记录发布内容
argument-hint: [branch]
---

# Release Command

执行发布流程：

1. 确认所有测试通过
2. 确认 review 完成
3. 将 `<branch>` 合并到当前分支（未指定时自动检测主分支 main/master）
4. 再次确认所有测试通过
5. 确认 review 完成
6. 执行 `/simplify`，简化代码
7. 检测当前是否为 Java Maven 项目（存在 pom.xml）；若是，按版本号建议规则给出建议版本，用户确认或修改后执行 `mvn versions:set`
8. 若已更改版本号，按 git 提交规范单独提交版本号变更
9. 修改 CHANGELOG.md 文件，记录发布内容
10. 按照 git 提交规范提交所有变更到本地仓库

## 使用

```
/release [branch]
```

- branch：可选，要合并到当前分支的源分支；省略时自动检测主分支（main 或 master）

## 版本号建议规则

读取 `pom.xml` 当前版本，按以下默认规则给出建议版本，用户确认或修改后执行 `mvn versions:set`：

- 当前为 SNAPSHOT 版本（如 `1.2.3-SNAPSHOT`）→ 建议发版 `1.2.3`，执行 `mvn versions:set -DremoveSnapshot=true`
- 当前为 release 版本（如 `1.2.3`）→ 建议下一版本 `1.2.4`，执行 `mvn versions:set -DnewVersion=1.2.4`
- 多模块项目加 `-DprocessAllModules=true`