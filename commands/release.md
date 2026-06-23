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
7. 检测项目类型（Maven / npm / Claude plugin），读取当前版本号，按版本号建议规则给出建议版本，用户确认或修改后执行对应类型的版本号变更
8. 若已更改版本号，按 git 提交规范单独提交版本号变更
9. 修改 CHANGELOG.md 文件，记录发布内容
10. 按照 git 提交规范提交所有变更到本地仓库

## 使用

```
/release [branch]
```

- branch：可选，要合并到当前分支的源分支；省略时自动检测主分支（main 或 master）

## 版本号建议规则

读取当前版本号，按以下默认规则给出建议版本，用户确认或修改后执行版本号变更：

- 当前为预发布/快照版本（如 `1.2.3-SNAPSHOT`、`1.2.3-beta.1`）→ 建议发正式版 `1.2.3`
- 当前为正式版本（如 `1.2.3`）→ 建议下一版本 `1.2.4`（默认 patch+1；含新功能可 minor+1，含破坏性变更可 major+1）

根据项目类型执行版本号变更：

### Maven 项目（存在 `pom.xml`）

- 读取 `pom.xml` 的 `<version>`
- SNAPSHOT 发版：`mvn versions:set -DremoveSnapshot=true`
- 下一版本：`mvn versions:set -DnewVersion=<版本>`
- 多模块项目加 `-DprocessAllModules=true`

### npm 项目（存在 `package.json`）

- 读取 `package.json` 的 `version` 字段
- 执行 `npm version patch|minor|major`（自动更新 version 并创建 git 提交与 tag）
- 不需要自动提交/tag 时加 `--no-git-tag-version`

### Claude plugin 项目（存在 `.claude-plugin/plugin.json`）

- 读取 `.claude-plugin/plugin.json` 的 `version` 字段
- 直接编辑该字段更新版本号
- 同步更新 `CHANGELOG.md`