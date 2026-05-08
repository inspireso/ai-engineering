# Event System

## KeyResolver 接口

**所有事件类必须实现 KeyResolver 接口:**

```java
public interface KeyResolver {
    Collection<String> getKeys();  // 返回事件追踪键
}
```

**事件类示例:**
```java
@Data
@NoArgsConstructor
@AllArgsConstructor
public class AfterCreated implements KeyResolver {
    private User user;
    private String invitationCode;

    @Override
    public Collection<String> getKeys() {
        return Lists.newArrayList(user.getCode(), invitationCode);
    }
}
```

## AbstractListener

**监听器基类（自动注册）:**

继承 `AbstractListener` 无需手动调用 `bus.register()`，Spring 容器启动时自动注册。

```java
@Component
public class StaffListener extends AbstractListener {

    @Subscribe
    @AllowConcurrentEvents  // 允许并发处理
    public void onStaffCreated(AfterStaffCreated event) {
        Optional.ofNullable(event.getUser())
            .filter(user -> !Strings.isNullOrEmpty(user.telOrEmail()))
            .ifPresent(user -> sendNotification(user, event.getAccount()));
    }
}
```

## @Subscribe 注解

**标记监听方法:**

```java
@Subscribe  // 标记事件处理方法
@AllowConcurrentEvents  // 允许并发处理（可选）
public void onEvent(MyEvent event) {
    // 处理事件
}
```

## EventBusService

**来自 BaseService:**

```java
// 同步发布（阻塞当前事务）
this.bus.post(new AfterCreated(user, code));

// 异步发布（不阻塞当前事务）
this.bus.asyncPost(new NotificationEvent(userId, message));
```

**何时使用:**
- `post()` - 需要在同一事务中处理（如日志记录、状态同步）
- `asyncPost()` - 不需要阻塞事务（如发送邮件、短信通知）

## 事件命名规范

**实际项目命名:**
- 类名: `AfterCreated`, `AfterDeleted`, `AfterChanged`, `AdminCreated`
- 包: `com.company.service.event`

## 完整示例

**事件类:**
```java
@Data
@NoArgsConstructor
@AllArgsConstructor
public class RoleEvents.AfterDeleted implements KeyResolver {
    private Role role;

    @Override
    public Collection<String> getKeys() {
        return Lists.newArrayList(role.getCode());
    }
}
```

**监听器:**
```java
@Slf4j
@Component
@RequiredArgsConstructor
public class RoleListener extends AbstractListener {

    private final NotificationService notificationService;

    @Subscribe
    @AllowConcurrentEvents
    public void onRoleDeleted(RoleEvents.AfterDeleted event) {
        notificationService.notifyAdmins("Role deleted: " + event.getRole().getName());
    }
}
```

**Service 发送:**
```java
@Service
public class RoleService extends BaseService {

    @Transactional(rollbackFor = Throwable.class)
    public void delete(Long id) {
        Role role = findById(id);
        this.bus.post(new RoleEvents.AfterDeleted(role));  // 同步事件
        roleRepository.deleteById(id);
    }
}
```

## 注意事项

1. **事件类必须实现 KeyResolver** - 提供事件追踪键
2. **监听器继承 AbstractListener** - 自动注册，无需手动
3. **@AllowConcurrentEvents** - 允许并发处理多个事件实例
4. **异步事件不阻塞事务** - 使用 `asyncPost()` 处理非关键任务
5. **事件类使用 @Data/@NoArgsConstructor/@AllArgsConstructor** - 简化代码