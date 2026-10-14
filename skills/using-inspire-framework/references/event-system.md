# Event System

## KeyResolver 接口

**事件类实现 KeyResolver 接口以提供事件追踪键**（框架不强制；实现后 `getKeys()` 会被消息中间件封装使用）:

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

## PropertyResolver 接口（RocketMQ SQL92 属性过滤）

**事件类实现 `PropertyResolver` 以透出消息属性**（框架不强制；实现后属性随消息发送，RocketMQ 消费端可用 SQL92 表达式按属性过滤）:

```java
public interface PropertyResolver {
    Map<String, String> getProperties();  // 键值均不得为空白
}
```

**事件类示例:**
```java
@Data
@NoArgsConstructor
@AllArgsConstructor
public class AfterPaid implements PropertyResolver {
    private String region;
    private BigDecimal amount;

    @Override
    public Map<String, String> getProperties() {
        // 数值比较由服务端按数值解析，需写规范数字串
        return Map.of("region", region, "amount", amount.toPlainString());
    }
}
```

**消费端配置**（`sql92` 与 TAG 订阅 `subscriptions` 平级，同一 topic 只能出现在其中一处）:
```yaml
inspire:
  event:
    rocketmq:
      consumer:
        subscriptions:
          topic-order: [com.foo.AfterPaid]        # TAG 过滤
        sql92:
          topic-logistics: "region = 'Hangzhou'"  # SQL92 属性过滤
```

**约束:**
- 属性 key 不得以 `_` 开头（框架保留 `_body_version`/`_serial_number`），不得使用 `Content-Type`/`TAGS`/`KEYS`；key 或 value 为空白时发送端抛 `IllegalArgumentException`
- 同一 topic 同时配置 TAG 与 SQL92 时应用启动失败（RocketMQ 每个 topic 只允许一个订阅表达式）
- broker 必须开启 `enablePropertyFilter=true`（默认 false），否则按 SQL92 订阅收不到消息
- Tag 在 SQL92 中作为属性名 `TAGS`，可与业务属性组合：`TAGS = 'com.foo.AfterPaid' AND region = 'Hangzhou'`

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

**标记监听方法**（来自 Guava EventBus：`com.google.common.eventbus.Subscribe` / `com.google.common.eventbus.AllowConcurrentEvents`）:

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
  - `debug=true` 时 `asyncPost()` 退化为同步 `post()`
  - 默认实现 `DefaultEventBusService` 为单线程池，异步事件按序（非并发）消费

## 投递语义（至少一次 + 幂等）—— 必须遵守

- **监听器必须幂等**：框架按「至少一次」投递，应用处理失败时消息不确认、由 MQ 原生重投，同一事件可能被处理多次。推荐开启 `inspire.event.bus.deterministic=true`（需 JPA），由 `DeterministicEventHandler` 基于 `event_consume_result` 表按消息 ID 去重。
- **需要感知失败时用 `postOrThrow()`**：分发后若有监听器抛异常则抛 `EventDispatchException`（首个异常为 cause），可配合事务回滚；常规 `post()` 保持 Guava 语义（异常不传播）。
- **发送端失败抛 `EventDeliveryException`**：不再静默丢弃；Kafka / Pub-Sub 使用客户端内建重试，Redis Stream / RocketMQ 使用 `EventDeliveries`（默认 3 次、间隔 100ms）。

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
        Role role = find(Role.class, id);
        this.bus.post(new RoleEvents.AfterDeleted(role));  // 同步事件
        delete(Role.class, id);
    }
}
```

## 注意事项

1. **事件类建议实现 KeyResolver** - 提供事件追踪键（消息中间件封装使用；框架不强制，不实现也能发布）
2. **监听器继承 AbstractListener** - 自动注册，无需手动
3. **@AllowConcurrentEvents** - 允许并发处理多个事件实例
4. **异步事件不阻塞事务** - 使用 `asyncPost()` 处理非关键任务
5. **事件类使用 @Data/@NoArgsConstructor/@AllArgsConstructor** - 简化代码