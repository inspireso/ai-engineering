# 工具使用优先级参考

## 工具优先级金字塔

**优先级顺序**: JDK 标准库 → Guava → Spring Framework → Inspireso Framework

```
┌─────────────────────────────┐
│   Inspireso Framework       │ ← JPA/Hibernate 特定优化 (Transform.copy)
├─────────────────────────────┤
│   Spring Framework          │ ← 框架层参数校验 (Assert, BeanUtils)
├─────────────────────────────┤
│   Guava                     │ ← JDK 之外首选 (Strings, Lists, Preconditions)
├─────────────────────────────┤
│   JDK 标准库                 │ ← 最高优先级,基础能力
└─────────────────────────────┘
```

**核心原则**:
1. JDK 能解决的,不用第三方库
2. Guava 提供 JDK 缺失的实用工具,优先使用
3. Spring Framework 用于框架层 API 和配置处理
4. Inspireso Framework 专为 JPA/Hibernate 场景设计,解决特定问题

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

## 4. Inspireso Framework 工具 (JPA/Hibernate 特定优化)

### Transform.copy() - 实体更新属性复制

```java
import org.inspireso.framework.util.Transform;

// ✅ 更新实体: 忽略 null 值,避免覆盖数据库已有值
User original = userRepository.findByCode(user.getCode()).orElse(new User());
user = Transform.copy(user, original, true, false);  // ignoreNullValue=true
original.audit(user.getCode());
return userRepository.saveAndFlush(original);

// ✅ 复制集合属性
Transform.copy(source, target, false, true);  // ignoreCollectionProperty=true
```

**参数含义**:
- `ignoreNullValue=true`: 不复制 null 值,避免前端传入 null 覆盖数据库已有值
- `ignoreCollectionProperty=true`: 忽略集合属性,避免 Hibernate 懒加载问题

**对比 Spring BeanUtils**:
| 场景 | 工具 | 原因 |
|------|------|------|
| JPA 实体更新 | Transform.copy(source, target, true, false) | 忽略 null 值 |
| 简单复制 | BeanUtils.copyProperties(source, target) | 无特殊需求 |

### Serializing.json() - JSON 序列化

```java
import org.inspireso.framework.util.Serializing;

// ✅ 序列化
String json = Serializing.json().toString(criteria);

// ✅ 反序列化
UserCriteria criteria = Serializing.json().toObject(json, UserCriteria.class);

// ✅ 反序列化 List
List<User> users = Serializing.json().toList(json, User.class);
```

**默认配置**:
- 时间格式: `yyyy-MM-dd HH:mm:ss`
- 时区: `GMT+8`
- 忽略未知属性
- 不序列化 null 值

### Cryptos - 加密工具

```java
import org.inspireso.framework.util.Cryptos;
import org.inspireso.framework.util.crypto.SymmetricCryptoFunction;
import org.inspireso.framework.util.crypto.AsymmetricCryptoFunction;

// ========== 对称加密 ==========

// --- ECB 模式（默认，确定性加密） ---

// ✅ AES-128/192/256 ECB 模式
byte[] key = Cryptos.aes256().generateKey();
byte[] encrypted = Cryptos.aes256().encode(plaintext, key);
byte[] decrypted = Cryptos.aes256().decode(encrypted, key);

// ✅ AES 字符串加解密（内部 Base64 编码）
String encryptedStr = Cryptos.aes128().encode(original, keyString);
String decryptedStr = Cryptos.aes128().decode(encryptedStr, keyString);

// ✅ SM4 ECB 模式（国密对称加密，128-bit 密钥）
byte[] sm4Key = Cryptos.sm4().generateKey();
byte[] encrypted = Cryptos.sm4().encode(plaintext, sm4Key);
byte[] decrypted = Cryptos.sm4().decode(encrypted, sm4Key);

// ✅ DES / DESede（已过时，仅用于兼容旧系统）
byte[] desKey = Cryptos.des().generateKey();
byte[] desedeKey = Cryptos.des_ede().generateKey();

// --- CBC 模式（推荐，随机 IV，非确定性加密） ---

// ✅ AES-128/192/256 CBC 模式（PKCS5Padding）
//    密文格式：[16 字节随机 IV][加密数据]
//    相同明文+密钥每次产生不同密文（IV 随机）
byte[] cbcKey = Cryptos.aes256Cbc().generateKey();
byte[] cbcEncrypted = Cryptos.aes256Cbc().encode(plaintext, cbcKey);
byte[] cbcDecrypted = Cryptos.aes256Cbc().decode(cbcEncrypted, cbcKey);

// ✅ AES CBC 字符串加解密
String cbcEncStr = Cryptos.aes128Cbc().encode("敏感数据", keyString);
String cbcDecStr = Cryptos.aes128Cbc().decode(cbcEncStr, keyString);

// ✅ SM4 CBC 模式（PKCS7Padding，国密标准推荐模式）
byte[] sm4CbcKey = Cryptos.sm4Cbc().generateKey();
byte[] sm4CbcEnc = Cryptos.sm4Cbc().encode(plaintext, sm4CbcKey);
byte[] sm4CbcDec = Cryptos.sm4Cbc().decode(sm4CbcEnc, sm4CbcKey);

// ========== 非对称加密 ==========

// --- PKCS#1 v1.5 填充（默认） ---

// ✅ RSA-1024/2048/4096 非对称加密（默认 PKCS#1 v1.5）
KeyPair rsaKeyPair = Cryptos.rsa().generateKeyPair();  // 默认 2048
byte[] rsaEncrypted = Cryptos.rsa().encode(bytes, rsaKeyPair.getPublic());
byte[] rsaDecrypted = Cryptos.rsa().decode(rsaEncrypted, rsaKeyPair.getPrivate());
// 私钥加密，公钥解密（签名场景）
byte[] signed = Cryptos.rsa().encode(bytes, rsaKeyPair.getPrivate());
byte[] verified = Cryptos.rsa().decode(signed, rsaKeyPair.getPublic());

// ✅ SM2 非对称加密（国密，256-bit EC 密钥）
KeyPair sm2KeyPair = Cryptos.sm2().generateKeyPair();
byte[] sm2Enc = Cryptos.sm2().encode(plaintext, sm2KeyPair.getPublic());
byte[] sm2Dec = Cryptos.sm2().decode(sm2Enc, sm2KeyPair.getPrivate());

// --- OAEP 填充（推荐，更高安全性） ---

// ✅ RSA-2048 OAEPWithSHA-256AndMGF1Padding
//    填充开销 66 字节，适用场景：需要更高安全性的非对称加密
KeyPair oaepKeyPair = Cryptos.rsaOaep().generateKeyPair();  // 默认 2048
byte[] oaepEnc = Cryptos.rsaOaep().encode(bytes, oaepKeyPair.getPublic());
byte[] oaepDec = Cryptos.rsaOaep().decode(oaepEnc, oaepKeyPair.getPrivate());

// ✅ RSA-1024/4096 OAEP（按需选择密钥长度）
KeyPair oaep1024 = Cryptos.rsaOaep_1024().generateKeyPair();
KeyPair oaep4096 = Cryptos.rsaOaep_4096().generateKeyPair();

// ========== 哈希 ==========

// ✅ SM3 哈希（国密，256-bit 摘要）
byte[] hash = Cryptos.sm3().digest(data);
String hexHash = Cryptos.sm3().digestHex("hello");  // 64 字符十六进制

// ========== 古典密码 ==========

// ✅ 凯撒密码（序列号混淆）
Cryptos.Caesar caesar = Cryptos.caesar("0123456789ABCDEF", 99);
String encoded = caesar.encode(2020, "0001");
String decoded = caesar.decode(2020, encoded);

// ✅ 维吉尼亚密码
Cryptos.Vigenere vigenere = Cryptos.vigenere("0123456789", 99);
String vEncoded = vigenere.encode("34355", "0001");
String vDecoded = vigenere.decode("34355", vEncoded);
```

**模式选择指南**:

| 场景 | 推荐算法 | 理由 |
|------|---------|------|
| 一般对称加密 | `aes256Cbc()` | CBC 模式 + IV 随机，安全性高于 ECB |
| 兼容旧系统 | `aes256()` | ECB 模式，确定性加密 |
| 国密对称加密 | `sm4Cbc()` | CBC 模式，国密标准推荐 |
| 一般非对称加密 | `rsaOaep()` | OAEP 填充，安全性高于 PKCS#1 v1.5 |
| 兼容旧系统 | `rsa()` | PKCS#1 v1.5，与旧系统互操作 |
| 国密非对称加密 | `sm2()` | 国密标准 |
| 国密哈希 | `sm3()` | 256-bit 国密标准摘要

### IdGenerator - ID 生成

```java
import org.inspireso.framework.util.id.IdGenerator;

// ✅ UUID
String uuid = IdGenerator.get();  // 无横线 UUID

// ✅ 短 ID
String id = IdGenerator.get(5);  // 5 位短序列号

// ✅ 36 进制格式化
String encoded = IdGenerator.formatString36(timestamp, 6);  // 缩短长度
```

### DateTimeUtils - 时间处理

```java
import org.inspireso.framework.util.DateTimeUtils;

// ✅ 日期范围查询
Date[] range = DateTimeUtils.today();  // [startOfDay, endOfDay]
Date[] range = DateTimeUtils.thisWeek();  // [周一, 周日]

// ✅ 开始/结束时刻规范化
beginDate = DateTimeUtils.withTimeAtStartOfDay(beginDate);  // 00:00:00
endDate = DateTimeUtils.withTimeAtEndOfDay(endDate);  // 次日 00:00:00

// ✅ 时间差计算
long days = DateTimeUtils.days(createdDate);
long hours = DateTimeUtils.hours(createdDate);
```

### Framework StringUtils / ObjectUtils (继承 Spring + Guava)

```java
import org.inspireso.framework.util.StringUtils;
import org.inspireso.framework.util.ObjectUtils;

// ✅ 业务逻辑非空检查
if (StringUtils.isNotEmpty(value)) {
    // 处理非空字符串
}

// ✅ 集合/Optional 判断
if (ObjectUtils.isNotEmpty(list)) {
    // 处理非空集合
}

if (ObjectUtils.isNullOrEmpty(optional)) {
    // 处理空 Optional
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
| **JPA 实体更新** | `Transform.copy(source, target, true, false)` | 忽略 null 值 |
| **简单属性复制** | `BeanUtils.copyProperties()` | 无特殊需求 |
| **配置值检查** | `StringUtils.hasText()` | Spring 标准方式 |
| **JSON 序列化** | `Serializing.json().toString()` | 框架默认配置 |
| **AES ECB 加密** | `Cryptos.aes256().encode()` | 确定性对称加密（兼容旧系统） |
| **AES CBC 加密** | `Cryptos.aes256Cbc().encode()` | 非确定性对称加密（推荐，IV 随机） |
| **SM4 国密对称加密** | `Cryptos.sm4().encode()` | 国密 ECB 模式 |
| **SM4 国密 CBC 加密** | `Cryptos.sm4Cbc().encode()` | 国密 CBC 模式（推荐） |
| **RSA 非对称加密** | `Cryptos.rsa().encode()` | PKCS#1 v1.5 填充（兼容旧系统） |
| **RSA OAEP 加密** | `Cryptos.rsaOaep().encode()` | OAEP SHA-256 填充（推荐） |
| **SM2 国密非对称加密** | `Cryptos.sm2().encode()` | 国密标准非对称加密 |
| **SM3 国密哈希** | `Cryptos.sm3().digestHex()` | 国密标准哈希 (256-bit) |
| **ID 生成** | `IdGenerator.get(5)` | 短序列号 |
| **日期范围** | `DateTimeUtils.today()` | 框架标准方式 |

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

### ❌ 实体更新直接 save() 不先查询

```java
// ❌ 错误: 直接 save(),null 值覆盖数据库已有值
userRepository.save(user);

// ✅ 正确: 先查询 → Transform.copy → save
User original = userRepository.findByCode(user.getCode()).orElse(new User());
user = Transform.copy(user, original, true, false);
return userRepository.saveAndFlush(original);
```

### ❌ 使用 BeanUtils.copyProperties() 更新实体

```java
// ❌ 错误: null 值覆盖数据库已有值
BeanUtils.copyProperties(user, original);

// ✅ 正确: 使用 Transform.copy 忽略 null
Transform.copy(user, original, true, false);
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

### ❌ 使用字符串拼接构建 JSON

```java
// ❌ 错误: 手动拼接 JSON
String json = "{\"code\":\"" + code + "\",\"name\":\"" + name + "\"}";

// ✅ 正确: 使用 Serializing
String json = Serializing.json().toString(user);
```

### ❌ 手动处理日期边界

```java
// ❌ 错误: 手动设置时分秒
Calendar cal = Calendar.getInstance();
cal.set(Calendar.HOUR_OF_DAY, 0);
cal.set(Calendar.MINUTE, 0);
cal.set(Calendar.SECOND, 0);

// ✅ 正确: 使用 DateTimeUtils
Date startOfDay = DateTimeUtils.withTimeAtStartOfDay(date);
```

---

## 选择原则总结

1. **JDK 标准库**: 基础能力优先使用 (Optional, Stream, Collector)
2. **Guava**: JDK 缺失的实用工具 (Strings, Lists, Preconditions, Splitter/Joiner)
3. **Spring Framework**: 框架层 API 校验和配置处理 (Assert, StringUtils.hasText)
4. **Inspireso Framework**: JPA/Hibernate 特定场景 (Transform.copy, Serializing, Cryptos, DateTimeUtils)
5. **禁止使用 Guava Optional**: 已废弃,必须使用 Java 8 Optional