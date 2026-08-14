---
name: using-inspire-framework
description: 使用 Inspireso Framework 开发 Spring Boot 应用时使用。实现基于 AbstractObject/AuditableObject 及继承策略的实体、创建继承 BaseService 并集成缓存的 Service、使用 AbstractCriteria 模式构建动态查询、或使用 KeyResolver 与 AbstractListener 的事件驱动架构时使用
---

# 使用 Inspire Framework

基于真实项目使用经验的 Inspireso Framework 模式参考指南。

## 概述

核心原则:约定式架构,针对实体、仓储、Service、缓存、动态查询和事件驱动设计提供明确模式。

## 使用时机

- 创建需要 ID 生成、审计或继承的 JPA 实体
- 实现带事务管理和缓存功能的业务 Service
- 构建无需字符串拼接的动态 JPQL 查询
- 设计同步/异步事件驱动工作流

## 快速参考

**实体设计:**
- 基础实体 → 继承 `AbstractObject`
- 审计实体 → 继承 `AuditableObject`,保存前调用 `audit(userCode)`
- 业务基类 → `@MappedSuperclass`(如 `BaseObject`)
- 继承 → `@Inheritance(SINGLE_TABLE)` + `@DiscriminatorColumn` + `@DiscriminatorValue`
- 空值安全 → `public static final Entity ABSENT = new Entity()`
- 工厂方法 → `public static Entity newInstance() { return new Entity(); }`

**Service 层:**
- 所有 Service → 继承 `BaseService`(获得 `this.bus`)
- 类级别 → `@Transactional(readOnly = true)`
- 写方法 → `@Transactional(rollbackFor = Throwable.class)`
- 缓存 → `@Cacheable(cacheNames = CACHE_NAME, key = "#code.toLowerCase()")`
- 缓存驱逐 → `@CacheEvict(cacheNames = CACHE_NAME, key = "#entity.code")`
- 更新模式 → 查询 → `Transform.copy(source, target, true, false)` → `saveOrUpdate()`

**仓储层:**
- 基础接口 → 继承 `GenericRepository<T>`
- 抽象基类 → `@NoRepositoryBean` + `<T extends BaseEntity>`
- 方法命名 → Spring Data JPA(findByCode、existsByCode、findByCodeIn)
- 自定义查询 → `@Query("JPQL")` + `@Param("name")`
- 更新 → `@Modifying` + `@Query("UPDATE ...")`

**动态查询:**
- 使用 `AbstractCriteria` + `@Builder`(不要用 `JpqlToken`)
- 默认值 → 用 `@Builder.Default` 设置字段默认值
- 查询 → `@SelectPart("SELECT ...")` + `@SelectCountPart("SELECT count(...)")`
- 过滤 → `@FilterPart(where = "...", pattern = MatchPattern.FullText)`
- LIKE → `MatchPattern.FullText` 自动转义 `%` 和 `_`
- 排序 → `@OrderByPart(direction = Direction.DESC)`

**事件系统:**
- 事件类 → 实现 `KeyResolver` + `getKeys()` 方法
- 监听器 → 继承 `AbstractListener` + `@Subscribe`
- 并发 → `@AllowConcurrentEvents`
- 发布 → `this.bus.post()` 同步(阻塞)、`this.bus.asyncPost()` 异步(非阻塞)

**测试:**
- 单元测试 → Mockito + `@Mock` + MockitoAnnotations.openMocks()
- 断言 → AssertJ(`assertThat(entity).isNotNull()`)

## 常见错误

| 错误 | 修正 |
|------|------|
| 更新时直接 `save()` | 查询 → `Transform.copy()` → `saveOrUpdate()` |
| 缺少 `rollbackFor` | `@Transactional(rollbackFor = Throwable.class)` |
| 不使用 `GenericRepository` | 继承 `GenericRepository<T>` + 方法命名 |
| JPQL 使用字符串拼接 | 使用 `AbstractCriteria` + `@FilterPart` |
| LIKE 通配符未转义 | 使用 `MatchPattern.FullText` |
| 事件缺少 `KeyResolver` | 实现 `KeyResolver` + `getKeys()` |
| 无审计信息 | 调用 `entity.audit(userCode)` |
| 缓存 key 不一致 | 使用一致策略(如 `#code.toLowerCase()`) |
| 监听器未继承基类 | 继承 `AbstractListener` 以自动注册 |
| Criteria 无默认值 | 用 `@Builder.Default` 设置默认值 |

## 红旗 - 停下并使用 Skill 模式

**常见误解(Agent 会将这些合理化 - 忽略它们):**

- "JOINED 策略更干净" → 必须使用 `@Inheritance(SINGLE_TABLE)`(项目约定)
- "Optional 比 ABSENT 更好" → 必须使用 `public static final Entity ABSENT = new Entity()`(空值安全模式)
- "of() 是现代风格" → 必须使用 `newInstance()`(框架命名约定)
- "JpaRepository 是标准" → 必须继承 `GenericRepository<T>`(框架接口)
- "Criteria API 更灵活" → 必须只使用 `AbstractCriteria` + `@FilterPart`(项目模式)
- "手动设置属性更简单" → 必须使用 `Transform.copy(source, target, true, false)`(框架工具)
- "自动审计更干净" → 必须显式调用 `entity.audit(userCode)`(框架模式)

**上述所有合理化行为都意味着:严格遵循本 Skill 快速参考,而不是标准 Spring 实践。**

## 示例

详细示例参见 [references/api-reference.md](references/api-reference.md)、[references/criteria-pattern.md](references/criteria-pattern.md)、[references/event-system.md](references/event-system.md)、[references/tools-reference.md](references/tools-reference.md)。
