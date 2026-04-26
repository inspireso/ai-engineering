---
name: refactor-analysis
version: 1.0.0
description: |
  重构影响分析。在跨文件修改前，先用 Grep/Glob 搜索所有引用点，
  列出完整影响清单和每文件修改范围评估，确认后再批量编辑。
  防止遗漏跨文件依赖（如缺少 import、接口签名不一致）。
allowed-tools:
  - Bash(git:*)
  - Grep
  - Glob
  - Read
  - AskUserQuestion
triggers:
  - 重构
  - 影响分析
  - 跨文件修改
  - impact analysis
  - 重构前检查
---

# Refactor Analysis — 重构影响分析

在执行跨文件重构或重命名之前，系统化分析影响范围，避免遗漏依赖。

---

## Step 1: 确认目标

确认用户要修改的类和/或方法：

```
目标类: [类名]
目标方法: [方法名] (如有)
修改类型: 重命名 / 改签名 / 移模块 / 改行为
```

## Step 2: 全面搜索引用

```bash
# 搜索 import 引用
grep -r "import .*\.目标类" --include="*.java" -l src/

# 搜索类名使用
grep -r "目标类" --include="*.java" -l src/

# 搜索方法名调用（如有具体方法）
grep -r "目标方法" --include="*.java" -l src/

# 搜索配置文件引用（如 MyBatis XML、Spring XML）
grep -r "目标类" --include="*.xml" -l src/

# 搜索测试文件引用
grep -r "目标类" --include="*.java" -l src/test/
```

对于非 Java 项目，调整 `--include` 到对应语言扩展名。

## Step 3: 输出影响清单

格式化输出为 markdown 表格：

```
## 影响清单

| 文件 | 引用类型 | 需修改内容 | 风险 |
|------|----------|-----------|------|
| src/main/java/.../FooService.java | import + 方法调用 | 更新 import 和方法调用 | 低 |
| src/test/java/.../FooServiceTest.java | 实例化 + 断言 | 更新构造器和断言 | 中 |
| src/main/resources/mapper/FooMapper.xml | resultType 引用 | 更新类全限定名 | 低 |

风险等级：低 = 机械替换 / 中 = 需理解上下文 / 高 = 影响公共 API 或外部调用
```

## Step 4: 逐文件修改

按风险从低到高依次修改，每完成一个文件立即验证：

```bash
# Java 项目
./mvnw compile -pl <模块名> 2>&1 | tail -20
```

若编译出错，立即修复再继续。

> 全量修改完成前**不要提交**，避免半成品进入版本控制。

## Step 5: 运行测试验证

```bash
# 运行相关模块的全量测试
./mvnw test -pl <模块名> 2>&1 | tail -20
# 或者运行特定测试类
./mvnw test -pl <模块名> -Dtest=<TestClass> 2>&1 | tail -20
```

确保所有测试通过。若有失败，优先修复再继续。

---

## 完成标准

- [ ] 所有引用点已在影响清单中列出
- [ ] 每文件修改完成，编译通过
- [ ] 相关测试全部通过
- [ ] 无遗留未处理的引用
