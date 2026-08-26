---
name: java-best-practices
description: 使用 Java 开发时约束工具类使用优先级和编码规范。JDK 标准库优先于 Guava 优先于 Spring Framework，以及 Java 编码通用最佳实践
---

# Java 最佳实践

Java 项目工具类使用优先级和编码规范参考。

## 概述

核心原则:以 JDK 标准库为根基,按优先级金字塔选择工具,避免引入不必要的依赖。

## 使用时机

- 任何 Java 项目开发中,需要选择工具类或 API 时
- 代码审查中判断工具使用是否合理
- 新项目初始化时建立编码约定

## 工具优先级金字塔

**优先级顺序**: JDK 标准库 → Guava → Spring Framework

```
┌───────────────────────────────┐
│   Spring Framework            │ ← 框架层 API 校验 (Assert, BeanUtils)
├───────────────────────────────┤
│   Guava                       │ ← JDK 之外首选 (Strings, Lists, Preconditions)
├───────────────────────────────┤
│   JDK 标准库                   │ ← 最高优先级,基础能力
└───────────────────────────────┘
```

**核心原则**:
1. JDK 能解决的,不用第三方库
2. Guava 提供 JDK 缺失的实用工具,优先使用
3. Spring Framework 用于框架层 API 和配置处理

> 如果项目使用了 Inspireso Framework,其特定工具(Transform.copy、Cryptos 等)优先级高于 Spring,参见 `using-inspire-framework` skill。

---

## 1. JDK 标准库 (最高优先级)

### Optional (使用 Java 8 Optional,不用 Guava Optional)

```java
// ✅ 正确: Java 8 Optional
import java.util.Optional;

Optional<User> user = userRepository.findByCode(code);
String name = Optional.ofNullable(user.getTel()).orElse(user.getEmail());

// ❌ 错误: 使用 Guava Optional (已废弃)
import com.google.common.base.Optional;  // 不要使用
```

### Stream 和 Collector

```java
// ✅ JDK Stream
List<String> codes = users.stream()
    .map(User::getCode)
    .filter(code -> code != null)
    .collect(Collectors.toList());

// ✅ JDK Comparator
Comparator<User> byName = Comparator.comparing(User::getName);
```

### Collection 工厂 (JDK 9+)

```java
// ✅ JDK 9+ 不可变集合
List<String> list = List.of("a", "b", "c");
Set<String> set = Set.of("a", "b", "c");
Map<String, Integer> map = Map.of("key", 1);

// ⚠️ JDK 8 需用 Guava: Lists.newArrayList(), Sets.newHashSet()
```

---

## 2. Guava 工具 (JDK 之外首选)

### Strings - 字符串处理

```java
// ✅ null 安全判断
if (Strings.isNullOrEmpty(value)) {
    return value;
}

// ✅ null 安全转换
String safeValue = Strings.nullToEmpty(value);  // Comparator 中避免 NPE

// ✅ 固定长度填充 (ID/编码生成)
String code = Strings.padStart(String.valueOf(count), 4, '0');  // "0001"
String padded = Strings.padEnd(text, 10, ' ');  // 左侧补空格
```

### Lists / Sets - 集合工厂

```java
// ✅ 快速创建可变集合
List<User> users = Lists.newArrayList();
Set<Group> groups = Sets.newHashSet();

// ✅ 单元素集合
return Lists.newArrayList(user);

// ✅ Optional 默认值
List<User> users = optional.orElse(Lists.newArrayList());
```

### Preconditions - 参数校验

```java
import static com.google.common.base.Preconditions.checkNotNull;
import static com.google.common.base.Preconditions.checkArgument;

// ✅ 工具类内部快速失败
public void register(Object object) {
    checkNotNull(object);  // NPE if null
    checkArgument(object.isValid(), "Object must be valid");
}
```

### Splitter / Joiner - 字符串分割连接

```java
// ✅ 定义静态常量
private static final Splitter DOT_SPLITTER = Splitter.on('.').trimResults();
private static final Joiner DOT_JOINER = Joiner.on('.').skipNulls();

// ✅ Map 分割连接
Map<String, String> params = Splitter.on("&").withKeyValueSeparator("=").split(query);
String query = Joiner.on("&").withKeyValueSeparator("=").useForNull("").join(params);

// ✅ 正则分割
List<String> parts = Splitter.on(Pattern.compile(" where ", Pattern.CASE_INSENSITIVE))
    .omitEmptyStrings()
    .split(jpql);
```

### ImmutableMap - 不可变结果

```java
// ✅ 少量键值对
return ImmutableMap.of("message", "success", "code", 200);

// ✅ 动态构建
ImmutableMap.Builder<String, Object> builder = ImmutableMap.builder();
builder.put("exception", e.getClass().getName());
builder.put("message", format(e));
return builder.build();
```

### Maps.newConcurrentMap() - 并发集合

```java
// ✅ 线程安全注册表
ConcurrentMap<Class<?>, EventBus> registry = Maps.newConcurrentMap();
```

---

## 3. Spring Framework 工具 (框架层 API)

### Assert - API 层参数校验

```java
import org.springframework.util.Assert;

// ✅ Service/Controller 层参数校验
public User findById(Long id) {
    Assert.notNull(id, "The given id must not be null!");
    Assert.hasText(code, "Code must not be empty");
    return userRepository.findById(id).orElse(null);
}
```

**对比**:
- **Spring Assert**: 用于框架层/API 层,提供友好异常消息
- **Guava Preconditions**: 用于工具类内部,static import 简洁调用

### BeanUtils.copyProperties() - 简单属性复制

```java
import org.springframework.beans.BeanUtils;

// ✅ 简单复制,无特殊需求
BeanUtils.copyProperties(source, target);
```

### StringUtils.hasText() - 配置检查

```java
import org.springframework.util.StringUtils;

// ✅ 配置值检查 (非空且有内容)
if (StringUtils.hasText(configValue)) {
    // 处理配置
}
```

### ObjectUtils.isEmpty() - 基础类型判断

```java
import org.springframework.util.ObjectUtils;

// ✅ 基础类型空判断
if (ObjectUtils.isEmpty(value)) {
    // 处理空值
}
```

---

## 决策表: 典型场景推荐工具

| 场景 | 推荐工具 | 原因 |
|------|----------|------|
| **null 安全判断** | `Strings.isNullOrEmpty()` | Guava 简洁高效 |
| **固定长度填充** | `Strings.padStart/padEnd()` | ID/编码生成标准做法 |
| **快速创建可变 List** | `Lists.newArrayList()` | JDK 8 无工厂方法 |
| **快速创建可变 Set** | `Sets.newHashSet()` | JDK 8 无工厂方法 |
| **工具类参数校验** | `Preconditions.checkNotNull()` | static import 简洁 |
| **API 层参数校验** | `Assert.notNull/hasText()` | 友好异常消息 |
| **字符串分割** | `Splitter.on().trimResults()` | 链式配置灵活 |
| **字符串连接** | `Joiner.on().skipNulls()` | null 安全处理 |
| **不可变结果返回** | `ImmutableMap.of/builder()` | 防止外部修改 |
| **并发 Map** | `Maps.newConcurrentMap()` | 线程安全工厂 |
| **简单属性复制** | `BeanUtils.copyProperties()` | 无特殊需求 |
| **配置值检查** | `StringUtils.hasText()` | Spring 标准方式 |

---

## Red Flags - 工具误用警示

### ❌ 使用 Guava Optional (已废弃)

```java
// ❌ 错误
import com.google.common.base.Optional;
Optional<User> user = Optional.of(user);

// ✅ 正确: 使用 Java 8 Optional
import java.util.Optional;
Optional<User> user = Optional.ofNullable(user);
```

### ❌ 手动拼接字符串分割/连接

```java
// ❌ 错误: 手动循环拼接
StringBuilder sb = new StringBuilder();
for (String part : parts) {
    if (sb.length() > 0) sb.append(".");
    sb.append(part);
}

// ✅ 正确: 使用 Joiner
String result = Joiner.on(".").skipNulls().join(parts);
```

### ❌ 手动判断集合非空

```java
// ❌ 错误: 手动判断
if (list != null && list.size() > 0) {
    // ...
}

// ✅ 正确: 使用工具
if (ObjectUtils.isNotEmpty(list)) {
    // ...
}
```

---

## 选择原则总结

1. **JDK 标准库**: 基础能力优先使用 (Optional, Stream, Collector)
2. **Guava**: JDK 缺失的实用工具 (Strings, Lists, Preconditions, Splitter/Joiner)
3. **Spring Framework**: 框架层 API 校验和配置处理 (Assert, StringUtils.hasText)
4. **禁止使用 Guava Optional**: 已废弃,必须使用 Java 8 Optional