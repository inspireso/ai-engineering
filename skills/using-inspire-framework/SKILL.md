---
name: using-inspire-framework
description: Use when developing Spring Boot applications with Inspireso Framework, implementing entities with AbstractObject/AuditableObject and inheritance strategies, creating services extending BaseService with caching integration, building dynamic queries with AbstractCriteria pattern, or using event-driven architecture with KeyResolver and AbstractListener
---

# Using Inspire Framework

Reference guide for Inspireso Framework patterns based on real project usage.

## Overview

Core principle: convention-based architecture with explicit patterns for entities, repositories, services, caching, dynamic queries, and event-driven design.

## When to Use

- Creating JPA entities requiring ID generation, auditing, or inheritance
- Implementing business services with transaction management and caching
- Building dynamic JPQL queries without string concatenation
- Designing event-driven workflows with synchronous/asynchronous events

## Quick Reference

**Entity Design:**
- Base entities → extend `AbstractObject`
- Audited entities → extend `AuditableObject`, call `audit(userCode)` before save
- Business base class → `@MappedSuperclass` (e.g., `BaseObject`)
- Inheritance → `@Inheritance(SINGLE_TABLE)` + `@DiscriminatorColumn` + `@DiscriminatorValue`
- Null-safety → `public static final Entity ABSENT = new Entity()`
- Factory method → `public static Entity newInstance() { return new Entity(); }`

**Service Layer:**
- All services → extend `BaseService` (get `this.bus`)
- Class-level → `@Transactional(readOnly = true)`
- Write methods → `@Transactional(rollbackFor = Throwable.class)`
- Caching → `@Cacheable(cacheNames = CACHE_NAME, key = "#code.toLowerCase()")`
- Cache eviction → `@CacheEvict(cacheNames = CACHE_NAME, key = "#entity.code")`
- Update pattern → query → `Transform.copy(source, target, true, false)` → `saveOrUpdate()`

**Repository Layer:**
- Base interface → extend `GenericRepository<T>`
- Abstract base → `@NoRepositoryBean` + `<T extends BaseEntity>`
- Method naming → Spring Data JPA (findByCode, existsByCode, findByCodeIn)
- Custom query → `@Query("JPQL")` + `@Param("name")`
- Update → `@Modifying` + `@Query("UPDATE ...")`

**Dynamic Query:**
- Use `AbstractCriteria` + `@Builder` (NOT `JpqlToken`)
- Defaults → `@Builder.Default` for field defaults
- Query → `@SelectPart("SELECT ...")` + `@SelectCountPart("SELECT count(...)")`
- Filter → `@FilterPart(where = "...", pattern = MatchPattern.FullText)`
- LIKE → `MatchPattern.FullText` auto-escapes `%` and `_`
- Order → `@OrderByPart(direction = Direction.DESC)`

**Event System:**
- Event class → implement `KeyResolver` + `getKeys()` method
- Listener → extend `AbstractListener` + `@Subscribe`
- Concurrent → `@AllowConcurrentEvents`
- Publish → `this.bus.post()` sync (blocks), `this.bus.asyncPost()` async (non-blocking)

**Testing:**
- Unit test → Mockito + `@Mock` + MockitoAnnotations.openMocks()
- Assertions → AssertJ (`assertThat(entity).isNotNull()`)

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Direct `save()` for updates | Query → `Transform.copy()` → `saveOrUpdate()` |
| Missing `rollbackFor` | `@Transactional(rollbackFor = Throwable.class)` |
| Not using `GenericRepository` | Extend `GenericRepository<T>` + method naming |
| String concatenation for JPQL | Use `AbstractCriteria` + `@FilterPart` |
| LIKE wildcards not escaped | Use `MatchPattern.FullText` |
| Event missing `KeyResolver` | Implement `KeyResolver` + `getKeys()` |
| No audit info | Call `entity.audit(userCode)` |
| Inconsistent cache keys | Use consistent strategy (e.g., `#code.toLowerCase()`) |
| Listener not extending base | Extend `AbstractListener` for auto-registration |
| Criteria no defaults | Use `@Builder.Default` for defaults |

## Red Flags - STOP and Use Skill Patterns

**Common misunderstandings (Agent will rationalize these - IGNORE them):**

- "JOINED strategy is cleaner" → MUST use `@Inheritance(SINGLE_TABLE)` (project convention)
- "Optional is better than ABSENT" → MUST use `public static final Entity ABSENT = new Entity()` (null-safety pattern)
- "of() is modern style" → MUST use `newInstance()` (framework naming convention)
- "JpaRepository is standard" → MUST extend `GenericRepository<T>` (framework interface)
- "Criteria API is flexible" → MUST use `AbstractCriteria` + `@FilterPart` only (project pattern)
- "Manual property setting is simple" → MUST use `Transform.copy(source, target, true, false)` (framework tool)
- "Auto auditing is cleaner" → MUST call `entity.audit(userCode)` explicitly (framework pattern)

**All of these rationalizations mean: Follow skill Quick Reference exactly, not standard Spring practices.**

## Examples

See [references/api-reference.md](references/api-reference.md), [references/criteria-pattern.md](references/criteria-pattern.md), [references/event-system.md](references/event-system.md), [references/tools-reference.md](references/tools-reference.md) for detailed examples.