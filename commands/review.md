---
name: review
description: PR review 流程 - 分析代码变更，检查是否符合规范，提供改进建议
---

# Review Command

执行代码 review 流程：

1. 分析当前分支与 base 分支的差异
2. 检查代码是否符合 AGENTS.md 规范
3. 检查安全护栏（硬编码密钥、危险操作等）
4. 检查测试覆盖
5. 提供改进建议

## 使用

```
/review [base-branch]
```

默认 base-branch 为 main。