---
name: qa
description: QA 测试流程 - 系统性测试功能，验证预期行为
---

# QA Command

执行 QA 测试流程：

1. 确定测试范围（当前变更影响的功能）
2. 编写/执行测试用例
3. 验证边界情况
4. 检查回归问题
5. 生成测试报告

## 使用

```
/qa [scope]
```

scope 可选：all, changed, specific-module