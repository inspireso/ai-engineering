---
name: release
description: 发布流程 - 合并代码、测试、构建、版本号变更、记录发布内容并打 tag
argument-hint: [branch]
---

# Release Command

执行发布流程：

1. 确认工作区干净且与远程同步：`git status --porcelain` 输出为空，`git fetch` 后 `git rev-list --count HEAD..@{u}` 为 0（不落后远程）；当前分支即发布目标分支。不满足则停止并提示
2. 确认 review 完成（当前分支变更已通过 `/review`）；若 review 产生代码修改，需在修改后执行步骤 3 的测试
3. 执行项目测试（Maven: `mvn test`；npm: `npm test`；Claude plugin: `bash -n hooks/*.sh` 并用 `jq empty` 校验所有 JSON 文件），要求退出码为 0；失败则立即停止发布流程
4. （可选）执行 `/simplify` 简化代码；若执行，重新运行步骤 3 的测试确保通过
5. 将 `<branch>` 合并到当前分支（未指定时自动检测主分支 main/master）；若源分支与当前分支相同（如直接在 main 上发版）则跳过合并，否则执行 `git merge --no-ff <branch>` 保留合并历史。若合并产生冲突，立即停止发布流程，提示用户手动解决或执行 `git merge --abort`，不自动 resolve 冲突
6. 若执行了合并，再次运行步骤 3 的测试，确保合并未引入回归；失败则询问用户是否 `git merge --abort`
7. 执行项目构建（Maven: `mvn -DskipTests package`；npm: `npm run build`；Claude plugin: 无构建步骤，跳过），确保可构建；失败则立即停止
8. 检测项目类型（Maven / npm / Claude plugin），读取当前版本号，按版本号建议规则给出建议版本，用户确认或修改后执行对应类型的版本号变更
9. 修改 `CHANGELOG.md`，按现有格式（`## <版本> (<日期>)` + `### 新增/变更` 分类，日期采用 `YYYY-MM-DD` 本地时区当日）记录发布内容
10. 若已更改版本号：先检查 `git tag -l v<版本>` 是否已存在，存在则停止并询问用户；按 git 提交规范（遵循 `git-commit` skill）将版本号变更与 CHANGELOG 一并提交（仅 `git add` 版本号文件与 `CHANGELOG.md`，提交信息：`chore(release): 发布 <版本>`），并创建 annotated tag `v<版本>`（`git tag -a v<版本> -m "发布 <版本>"`）
11. 提示用户是否推送到远程：显示当前分支与远程追踪分支（如 `main → origin/main`）及待推送提交数，用户确认后分别执行 `git push` 与 `git push --tags` 并校验退出码；若 `git push` 成功但 `git push --tags` 失败，提示"远程分支已推送但 tag 未推送，发版不完整"并给出 `git push --tags` 重试命令

## 使用

```
/release [branch]
```

- branch：可选，要合并到当前分支的源分支；省略时自动检测主分支（main 或 master）

## 版本号建议规则

读取当前版本号，按以下默认规则给出建议版本，用户确认或修改后执行版本号变更：

- 当前为预发布/快照版本（如 `1.2.3-SNAPSHOT`、`1.2.3-beta.1`）→ 建议发正式版 `1.2.3`
- 当前为正式版本（如 `1.2.3`）→ 建议下一版本 `1.2.4`（默认 patch+1；含新功能可 minor+1，含破坏性变更可 major+1）

根据项目类型执行版本号变更（版本号变更统一交由步骤 10 提交与打 tag，此处仅修改版本号）：

### Maven 项目（存在 `pom.xml`）

- 读取 `pom.xml` 的 `<version>`；若根 pom 无 `<version>` 或为属性引用（如 `${revision}`），沿 parent 链查找，或用 `mvn help:evaluate -Dexpression=revision -q -DforceStdout` 读取属性值
- SNAPSHOT 发版：`mvn versions:set -DremoveSnapshot=true`
- 下一版本：`mvn versions:set -DnewVersion=<版本>`
- 多模块项目加 `-DprocessAllModules=true`

### npm 项目（存在 `package.json`）

- 读取 `package.json` 的 `version` 字段
- 执行 `npm version patch|minor|major --no-git-tag-version`（仅更新 version 字段，不自动提交与打 tag，交由步骤 10 统一处理）

### Claude plugin 项目（存在 `.claude-plugin/plugin.json`）

- 读取 `.claude-plugin/plugin.json` 的 `version` 字段
- 直接编辑该字段更新版本号
- 同步更新 `CHANGELOG.md`（步骤 9）
