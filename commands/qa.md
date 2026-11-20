---
name: qa
description: QA 测试流程 - 以变更影响面驱动的轻量功能验证；端到端浏览器 QA 走 gstack:qa，不在此重复
argument-hint: [scope]
---

# QA Command

执行轻量 QA 测试流程（功能与回归验证；端到端浏览器交互测试走 `gstack:qa`）：

1. 确定测试范围（当前变更影响的功能）
2. 编写/执行测试用例
3. 验证边界情况
4. 检查回归问题
5. 生成测试报告：写明实际执行的命令、通过/失败数量、未覆盖项；没有执行结果不得声称通过

## 使用

```
/qa [scope]
```

scope 可选：all, changed, specific-module
