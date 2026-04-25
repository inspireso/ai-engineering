---
name: ship
description: 发布流程 - 合并代码、部署、监控
---

# Ship Command

执行发布流程：

1. 确认所有测试通过
2. 确认 review 完成
3. 合并到主分支
4. 部署到目标环境
5. 监控部署状态

## 使用

```
/ship [target]
```

target 可选：staging, production