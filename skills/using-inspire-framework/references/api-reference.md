# API Reference

## GenericRepository<T>

继承 `JpaRepository<T, Long>` + `JpaSpecificationExecutor<T>` + `QueryRepository`

**常用方法命名查询**(需在自定义仓库接口中按 Spring Data 命名约定声明):
```java
Optional<T> findByCode(String code);
List<T> findByCodeIn(Iterable<String> codes);
boolean existsByCode(String code);
List<T> findByCodeStartingWith(String code);
Page<T> findByNameLike(String name, Pageable pageable);
```

**自定义 JPQL:**
```java
@Query("SELECT u FROM User u LEFT JOIN FETCH u.groups WHERE u.code = :code")
Optional<User> findByCodeWithGroups(@Param("code") String code);

@Query("SELECT count(u) FROM User u WHERE u.code LIKE CONCAT(:code, '%')")
int countByCodeLike(@Param("code") String code);
```

**更新操作:**
```java
@Modifying
@Query("UPDATE User u SET u.status=:status, u.version=u.version+1 WHERE u.id=:id")
int updateStatus(@Param("id") Long id, @Param("status") Status status);
```

**抽象 Repository:**
```java
@NoRepositoryBean
public interface GroupRepository<T extends Group> extends GenericRepository<T> {
    Optional<T> findByCode(String code);
    List<T> findByCodeIn(Iterable<String> codes);
}
```

## BaseService

**继承获得:**
- `SimpleRepository simpleRepository` - 数据访问
- `EventBusService bus` - 事件总线

**核心方法:**
```java
// 查询
T find(Class<T> entityClass, long id);
List<T> find(Class<T> entityClass, Iterable<JpqlToken> tokens);
Page<T> find(Class<T> entityClass, Iterable<JpqlToken> tokens, Pageable pageable);
Slice<T> slice(Class<T> entityClass, Iterable<JpqlToken> tokens, Pageable pageable);

// 更新（关键模式）
@Transactional(rollbackFor = Throwable.class)
T saveOrUpdate(T object);  // 新实体直接保存，已有实体查询后复制属性再保存

// 删除
@Transactional(rollbackFor = Throwable.class)
void delete(Class<T> entityClass, long id);
void delete(T entity);
```

**实际更新模式**(假设子类已声明自定义仓库字段,如 `private UserRepository userRepository;`):
```java
@Transactional(rollbackFor = Throwable.class)
public User saveOrUpdate(User user) {
    User original = userRepository.findByCode(user.getCode())
        .orElse(new User());
    Transform.copy(user, original, true, false);  // 复制属性到数据库实体
    original.audit(user.getCode());  // 设置审计
    return userRepository.saveAndFlush(original);
}
```

## Transform.copy()

**参数说明:**
```java
Transform.copy(source, target, ignoreNullValue, ignoreCollectionProperty)
```

- `source` - 源对象（新数据）
- `target` - 目标对象（数据库实体），返回值即 `target`
- `ignoreNullValue` - `true` 跳过 null 值，避免前端传入的 null 覆盖数据库已有值
- `ignoreCollectionProperty` - `true` 跳过集合属性，避免 Hibernate 懒加载问题

**正确用法:**
```java
Transform.copy(user, original, true, false);  // null 值不覆盖，集合属性照常复制
original.audit(user.getCode());  // 设置审计信息
repository.saveAndFlush(original);  // 保存数据库实体
```

## AuditableObject

**继承获得审计字段:**
- `long version` - 乐观锁版本号（`@Version`，默认值 1）
- `String createdBy` - 创建人
- `LocalDateTime createdTime` - 创建时间（字段为 `Date`，getter/setter 暴露为 `LocalDateTime`）
- `String lastModifiedBy` - 修改人
- `LocalDateTime lastModifiedTime` - 修改时间（同 `createdTime`）

**设置审计:**
```java
entity.audit(userCode);  // 新实体写 createdBy/createdTime；始终更新 lastModifiedBy/lastModifiedTime；auditor 为空时回退 DEFAULT_AUDITOR
```

## EventBusService

**来自 BaseService:**
```java
this.bus.post(event);       // 同步发布（阻塞当前事务）
this.bus.asyncPost(event);  // 异步发布（不阻塞）
```

**监听器注册:**
继承 `AbstractListener` 自动注册，无需手动调用 `register()`。