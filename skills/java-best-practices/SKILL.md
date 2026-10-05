---
name: java-best-practices
description: 使用 Java 开发时约束工具类使用优先级、包结构分层和编码规范。工具类优先 JDK → Guava → Spring；包结构遵循单向分层依赖、优先事件驱动；编码遵循命名、异常、日期时间等最佳实践
---

# Java 最佳实践

Java 项目工具类使用优先级和编码规范参考。

## 概述

核心原则:以 JDK 标准库为根基,按优先级金字塔选择工具,避免引入不必要的依赖;同时遵循 Java 通用编码规范。

## 使用时机

- 任何 Java 项目开发中,需要选择工具类或 API 时
- 代码审查中判断工具使用是否合理
- 新项目初始化时建立编码约定
- 创建新包或组织模块结构时
- 编写 Java 代码时需要遵循命名、异常、日期时间等规范

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
String name = user.map(User::getTel).orElseGet(User::getEmail);

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

## 4. 命名规范

### 类与接口

```java
// ✅ 类名: 大驼峰 (PascalCase),名词或名词短语
public class UserService {}
public class OrderRepository {}

// ✅ 接口名: 大驼峰,不加 I 前缀(Java 惯例)
public interface UserRepository {}

// ❌ 错误: 接口加 I 前缀(C# 风格)
public interface IUserRepository {}
```

### 方法与变量

```java
// ✅ 方法名: 小驼峰 (camelCase),动词或动词短语
public User findByCode(String code) {}
public void createOrder(Order order) {}

// ✅ 变量名: 小驼峰,名词,有明确含义
User currentUser;
List<Order> pendingOrders;

// ❌ 错误: 无意义缩写/单字母(循环变量除外)
User u;
List<Order> list1;
```

### 常量

```java
// ✅ 常量: 全大写 + 下划线分隔
public static final String DEFAULT_USER_CODE = "SYSTEM";
public static final int MAX_RETRY_TIMES = 3;

// ❌ 错误: 常量用小驼峰
public static final String defaultUserCode = "SYSTEM";
```

### 布尔变量命名

```java
// ✅ 布尔值: is/has/can 前缀,读起来像问句
boolean isActive;
boolean hasPermission;
boolean canEdit;

// ❌ 错误: 无前缀,语义不清
boolean active;
boolean permission;
```

---

## 5. 异常处理

### 异常捕获原则

```java
// ✅ 正确: 捕获具体异常,不吞异常
try {
    userRepository.save(user);
} catch (DataAccessException e) {
    log.error("保存用户失败: {}", user.getCode(), e);
    throw new BusinessException("用户保存失败", e);
}

// ❌ 错误: 捕获后不处理(吞异常)
try {
    userRepository.save(user);
} catch (Exception e) {
    // 什么都不做,异常被静默吞掉
}
```

### 异常转换

```java
// ✅ 正确: 底层异常转换为业务异常
public User findByCode(String code) {
    try {
        return userRepository.findByCode(code).orElse(null);
    } catch (DataAccessException e) {
        throw new BusinessException("查询用户失败", e);
    }
}

// ❌ 错误: 直接抛出原始异常,暴露内部实现
public User findByCode(String code) throws SQLException {
    // 方法签名泄漏 JDBC 细节
}
```

### 日志记录

```java
// ✅ 正确: 记录异常上下文 + 异常对象(保留堆栈)
log.error("处理用户 {} 失败", user.getCode(), e);

// ❌ 错误: 只记录 message,丢失堆栈
log.error("处理用户失败: " + e.getMessage());
```

---

## 6. 日期时间 (java.time 取代 Date/Calendar)

### 时间类型选择

```java
// ✅ 正确: 使用 java.time (Java 8+)
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.Instant;

LocalDate date = LocalDate.now();
LocalDateTime dateTime = LocalDateTime.now();
Instant instant = Instant.now();  // 时间戳,UTC

// ❌ 错误: 使用过时的 Date/Calendar
import java.util.Date;
import java.util.Calendar;

Date date = new Date();  // 过时,易出错
Calendar cal = Calendar.getInstance();  // 过时
```

### 时间解析/格式化

```java
// ✅ 正确: DateTimeFormatter 线程安全
DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
String text = LocalDateTime.now().format(formatter);
LocalDateTime parsed = LocalDateTime.parse(text, formatter);

// ❌ 错误: SimpleDateFormat 非线程安全
SimpleDateFormat format = new SimpleDateFormat("yyyy-MM-dd");  // 线程安全问题
```

### 时间计算

```java
// ✅ 正确: 不可变 API,链式操作
LocalDate tomorrow = LocalDate.now().plusDays(1);
LocalDate firstDayOfMonth = LocalDate.now().withDayOfMonth(1);

// ❌ 错误: 手动计算毫秒/秒
long nextDayMillis = System.currentTimeMillis() + 24 * 60 * 60 * 1000;  // 易错
```

---

## 7. 包结构与分层

### 依赖方向

包结构自上而下按层排列,依赖方向单一:**下层依赖上层,只能向上依赖,不能向下依赖**,禁止反向依赖与循环依赖。

Spring Boot 项目可按以下顺序组织模块:

```
config            ← 配置与基础设施
domain            ← 领域模型(实体、值对象、枚举)
repository        ← 数据访问
service           ← 业务逻辑
xxxConfiguration  ← 装配与启动(如 OrderConfiguration)
```

位置靠后的层(下层)依赖位置靠前的层(上层),反之不允许:

```java
// ✅ 正确: service(下层) 依赖 domain、repository(上层)
package com.example.order.service;

import com.example.order.domain.Order;
import com.example.order.repository.OrderRepository;

// ❌ 错误: domain(上层) 反向依赖 service(下层)
package com.example.order.domain;

import com.example.order.service.OrderService;
```

### 事件驱动

优先使用事件驱动模式解耦模块间协作:

- 事件定义: `service/event` 包下,命名为 `XxxEvents`
- 事件发布: 在 `service` 中使用
- 事件监听: 放在 `service/event/listener` 包中

```
service/
├── OrderService.java               ← 事件发布
└── event/
    ├── OrderEvents.java            ← 事件定义
    └── listener/
        └── OrderEventListener.java ← 事件监听
```

### 最小可见性

类的可见性取满足需求的最小级别,定义位置尽量靠近使用位置:

- 不需要 public 的类不加 public(优先包级私有)
- 能用内部类解决的用内部类
- 仅为单个类服务的辅助类/枚举,尽可能定义在该类内部或同一文件

```java
// ✅ 正确: 仅同包使用,不加 public
class OrderCodeGenerator {
    String next() { ... }
}

// ✅ 正确: 仅本类使用,用私有内部类
public class OrderService {
    private static class PriceCalculator {
        BigDecimal calculate(Order order) { ... }
    }
}

// ❌ 错误: 仅内部使用却声明 public
public class OrderCodeGenerator { }

// ❌ 错误: 仅 OrderService 使用的辅助类,单独定义为 public 类
public class PriceCalculator { }
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

### ❌ 使用过时的 Date/Calendar

```java
// ❌ 错误: 使用 Date/Calendar
Date date = new Date();
Calendar cal = Calendar.getInstance();

// ✅ 正确: 使用 java.time
LocalDate date = LocalDate.now();
LocalDateTime dateTime = LocalDateTime.now();
```

### ❌ 捕获异常后静默吞掉

```java
// ❌ 错误: 吞异常
try {
    doSomething();
} catch (Exception e) {
    // 什么都不做
}

// ✅ 正确: 记录并处理
try {
    doSomething();
} catch (Exception e) {
    log.error("操作失败", e);
    throw new BusinessException("操作失败", e);
}
```

---

## 总结

**工具类选择**:
1. **JDK 标准库**: 基础能力优先使用 (Optional, Stream, Collector)
2. **Guava**: JDK 缺失的实用工具 (Strings, Lists, Preconditions, Splitter/Joiner)
3. **Spring Framework**: 框架层 API 校验和配置处理 (Assert, StringUtils.hasText)
4. **禁止使用 Guava Optional**: 已废弃,必须使用 Java 8 Optional

**编码规范**:
5. **命名**: 类大驼峰、方法/变量小驼峰、常量全大写、布尔加 is/has/can 前缀
6. **异常**: 捕获具体异常,不吞异常,底层异常转业务异常,记录堆栈
7. **日期时间**: 使用 java.time,弃用 Date/Calendar/SimpleDateFormat

**包结构与分层**:
8. **依赖方向**: 下层依赖上层,只能向上依赖,禁止反向依赖与循环依赖
9. **模块组织**: Spring Boot 按 config、domain、repository、service、xxxConfiguration 顺序组织
10. **事件驱动**: 优先事件驱动模式,XxxEvents 定义在 service/event,在 service 中发布,service/event/listener 中监听
11. **可见性**: 不需要 public 就不 public,能用内部类就用内部类,定义靠近使用位置