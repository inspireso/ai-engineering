# RED Phase 测试结果总结

## 测试目的

验证在没有 skill 指导的情况下，Agent/开发者是否会做出与实际项目架构不一致的决策。

## 测试场景与结果

### 场景 1：实体继承设计

**任务**：创建组织和部门两种实体，都继承自 Group 基类。

**Agent 的实际决策**（WITHOUT skill）：
```java
@Inheritance(strategy = InheritanceType.JOINED)  // ❌ 错误
public abstract class Group extends AuditableObject {
    // 无 ABSENT 常量  // ❌ 错误
}

// 静态工厂方法用 of()  // ⚠️ 不一致
public static Organization of(String code, String name) { ... }
```

**实际项目的正确做法**（WITH skill）：
```java
@Inheritance(strategy = InheritanceType.SINGLE_TABLE)  // ✅ 正确
@DiscriminatorColumn(name = "type", discriminatorType = DiscriminatorType.STRING)
public class Group extends AuditableObject {
    public static final Group ABSENT = new Group();  // ✅ 空对象模式
}

// 静态工厂方法用 newInstance()  // ✅ 正确
public static Role newInstance() { return new Role(); }
```

**合理化借口**：
- "规范化设计，避免单表策略中的大量 NULL 列"
- "空对象模式不适用于实体继承设计"

---

### 场景 2：Repository 设计

**任务**：创建 UserRepository 和 GroupRepository，需要查询和更新方法。

**Agent 的实际决策**（WITHOUT skill）：
```java
public interface UserRepository extends JpaRepository<User, Long> {  // ❌ 错误
    Optional<User> findByCode(String code);

    @Transactional  // ⚠️ 缺少 rollbackFor = Throwable.class
    @Modifying
    @Query("UPDATE User u SET u.status = :status WHERE u.code = :code")
    int updateStatusByCode(@Param("code") String code, @Param("status") UserStatus status);
}

@NoRepositoryBean
public interface GroupRepository<T extends Group> extends JpaRepository<T, Long> {  // ❌ 错误
    // ...
}
```

**实际项目的正确做法**（WITH skill）：
```java
public interface UserRepository extends GenericRepository<User> {  // ✅ 正确
    Optional<User> findByCode(String code);

    @Transactional(rollbackFor = Throwable.class)  // ✅ 正确
    @Modifying
    @Query("UPDATE User u SET u.status=:status WHERE u.id=:id")
    int updateStatus(@Param("id") Long id, @Param("status") Status status);
}

@NoRepositoryBean
public interface GroupRepository<T extends Group> extends GenericRepository<T> {  // ✅ 正确
    // ...
}
```

**合理化借口**：
- "JpaRepository 是最标准、最完整"
- "符合 Spring Data JPA 官方推荐"

---

### 场景 3：Service 缓存集成

**任务**：实现 UserService 的查询和保存方法，考虑缓存。

**Agent 的实际决策**（WITHOUT skill）：
```java
@Service
@Transactional(readOnly = true)
public class UserServiceImpl implements UserService {

    @Cacheable(value = "users", key = "#code")  // ⚠️ 缺少 .toLowerCase()
    public Optional<User> findByCode(String code) {
        return userRepository.findByCode(code);
    }

    @Transactional(rollbackFor = Throwable.class)
    @CacheEvict(value = "users", key = "#result.code")  // ⚠️ 缓存名无常量
    public User saveOrUpdate(User user) {
        User existing = userRepository.findById(user.getId())
            .orElseThrow(...);
        existing.setName(user.getName());  // ⚠️ 直接设置属性
        existing.setStatus(user.getStatus());  // ⚠️ 不使用 Transform.copy
        return userRepository.save(existing);  // ⚠️ 不调用 audit(userCode)
    }
}
```

**实际项目的正确做法**（WITH skill）：
```java
@Service
public class UserService extends BaseService {

    static final String USER_CACHE_NAME = "org:user:v1";  // ✅ 缓存名常量

    @Cacheable(cacheNames = USER_CACHE_NAME, key = "#code.toLowerCase()")  // ✅ 正确
    public Optional<User> findByCode(String code) {
        return userRepository.findByCode(code);
    }

    @Transactional(rollbackFor = Throwable.class)
    @CacheEvict(cacheNames = USER_CACHE_NAME, key = "#user.code.toLowerCase()")
    public User saveOrUpdate(User user) {
        User original = userRepository.findByCode(user.getCode()).orElse(new User());
        user = Transform.copy(user, original, true, false);  // ✅ 使用 Transform
        original.audit(user.getCode());  // ✅ 设置审计
        return userRepository.saveAndFlush(original);
    }
}
```

**合理化借口**：
- "简单字符串键，无需组合键"
- "避免 JPA merge() 创建新的持久化上下文"
- "让 JPA Auditing 自动处理"

---

### 场景 4：Criteria 查询构建（用户调查）

**任务**：创建用户搜索表单，支持多字段过滤（姓名、邮箱、电话）。

**用户的实际选择**（WITHOUT skill）：
- ❌ 使用 JPA Criteria API（而非 AbstractCriteria + @FilterPart）
- ❌ 直接拼接 %（而非使用 MatchPattern.FullText 自动转义）

**实际项目的正确做法**（WITH skill）：
- ✅ 仅使用 AbstractCriteria + @Builder + @FilterPart
- ✅ 使用 MatchPattern.FullText 自动转义 % 和 _

**合理化借口**：
- "JPA Criteria API 是标准的动态查询方式"
- "直接拼接 % 更简单直观"

---

### 场景 5：事件系统实现（用户调查）

**任务**：订单创建后发送邮件通知的事件系统。

**用户的实际选择**（WITHOUT skill）：
- ✅ 实现 KeyResolver 接口（正确）
- ⚠️ 使用 @Subscribe（缺少继承 AbstractListener 和 @AllowConcurrentEvents）
- ✅ 异步发布 asyncPost()（正确）

**实际项目的正确做法**（WITH skill）：
```java
// ✅ 事件类实现 KeyResolver
@Data
public class AfterCreated implements KeyResolver {
    private User user;
    private String invitationCode;

    @Override
    public Collection<String> getKeys() {
        return Lists.newArrayList(user.getCode(), invitationCode);
    }
}

// ✅ 监听器继承 AbstractListener + @AllowConcurrentEvents
@Component
public class StaffListener extends AbstractListener {

    @Subscribe
    @AllowConcurrentEvents  // ✅ 允许并发处理
    public void onStaffCreated(AfterStaffCreated event) {
        sendNotification(event.getUser(), event.getAccount());
    }
}

// ✅ Service 使用 this.bus（来自 BaseService）
this.bus.asyncPost(new UserEvents.AfterCreated(user, code));
```

**合理化借口**：
- "使用 @Subscribe 是标准的事件监听方式"

---

## 关键发现总结

### 1. 架构不一致问题

**Agent/开发者普遍的错误模式**：

| 错误类型 | Agent 的选择 | 实际项目做法 | 影响 |
|---------|------------|------------|------|
| 继承策略 | JOINED | SINGLE_TABLE | 表结构不一致，性能差异 |
| Repository | JpaRepository | GenericRepository | 缺少框架特有功能 |
| 空对象模式 | 不使用 | ABSENT 常量 | null 检查代码冗余 |
| 缓存键 | #code | #code.toLowerCase() | 缓存失效，大小写不一致 |
| 属性复制 | 直接设置 | Transform.copy | 缺少框架优化 |
| 审计设置 | 自动填充 | audit(userCode) | 审计信息不一致 |
| 动态查询 | Criteria API | AbstractCriteria | 代码复杂度高 |
| LIKE 通配符 | 直接拼接 % | MatchPattern.FullText | SQL 注入风险 |

### 2. 合理化借口模式

Agent/开发者会使用看似合理的借口来支持错误决策：

**常见借口类型**：
- "这是标准做法" - 使用 Spring Data JPA 标准，而非框架特有模式
- "更简单直观" - 避免框架抽象，直接实现
- "规范化设计" - 理论上的最佳实践，而非实际项目约定
- "性能更好" - 理论上的性能优化，实际未验证

**这些借口的问题**：
- ✅ 听起来很有道理
- ❌ 与实际项目架构不一致
- ❌ 缺少框架特有的优化和约束
- ❌ 会导致不同开发者使用不同模式

### 3. Skill 的必要性验证

**测试证明**：

1. **Agent 无法自动发现框架特有模式**
   - 不知道 SINGLE_TABLE 策略
   - 不知道 GenericRepository 接口
   - 不知道 AbstractCriteria 模式
   - 不知道 Transform.copy 工具

2. **Agent 会使用"标准做法"替代框架约定**
   - JpaRepository 代替 GenericRepository
   - Criteria API 代替 AbstractCriteria
   - 直接设置属性代替 Transform.copy

3. **合理化借口会掩盖问题**
   - 所有错误决策都有合理的解释
   - 开发者会坚持自己的"正确"做法
   - 导致代码审查时的争论

4. **Skill 可以解决这些问题**
   - 提供明确的框架约定
   - 提供 Quick Reference 快速决策
   - 提供 Common Mistakes 对比错误做法
   - 提供 Red Flags 识别问题

---

## 结论

**RED Phase 测试成功验证了 skill 的必要性**：

- ✅ Agent/开发者会在没有 skill 的情况下做出错误决策
- ✅ 错误决策都有看似合理的借口
- ✅ 这些错误会导致架构不一致和潜在问题
- ✅ Skill 提供的明确约定可以避免这些问题

**下一步**：GREEN Phase - 验证 WITH skill 情况下 Agent 是否会遵循正确模式。