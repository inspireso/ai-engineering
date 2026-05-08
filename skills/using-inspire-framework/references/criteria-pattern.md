# Criteria Pattern

## AbstractCriteria 使用

**实际项目仅使用 AbstractCriteria + 注解模式，不使用 JpqlToken 手动构建。**

## Builder 模式

```java
@Builder
public class UserCriteria extends AbstractCriteria {

    @Builder.Default
    @SelectPart("SELECT DISTINCT u FROM User u LEFT JOIN FETCH u.groups g")
    private boolean select = true;

    @Builder.Default
    @SelectCountPart("SELECT count(DISTINCT u) FROM User u LEFT JOIN u.groups g")
    private boolean count = true;

    @FilterPart(where = "u.code LIKE :query OR u.name LIKE :query",
                pattern = FilterPart.MatchPattern.FullText)
    private String query;

    @Builder.Default
    @FilterPart(where = "u.type = :type")
    private User.Type type = User.Type.STAFF;

    @Builder.Default
    @OrderByPart(direction = OrderByPart.Direction.DESC)
    private String orderBy = "u.createdTime";

    @Override
    protected void setupCollect() {}
}
```

**使用:**
```java
UserCriteria criteria = UserCriteria.builder()
    .query("search text")
    .type(User.Type.STAFF)
    .build();

List<JpqlToken> tokens = JpqlTokens.collect(criteria);
List<User> users = find(User.class, tokens);
```

## @FilterPart 注解

**属性:**
- `where` - JPQL WHERE 条件（必须包含参数占位符 `:paramName`）
- `pattern` - LIKE 匹配模式（可选）
- `name` - 参数名（默认使用字段名）

**MatchPattern 模式:**
- `None` - 不添加通配符，原值匹配
- `Left` - 左匹配，添加 `%` 在右侧（`value%`）
- `Right` - 右匹配，添加 `%` 在左侧（`%value`）
- `FullText` - 全文匹配，前后添加 `%`（`%value%`）

**自动转义:**
`MatchPattern.FullText` 会自动转义 LIKE 通配符 `%` 和 `_` 为 `\%` 和 `\_`。

## @SelectPart / @SelectCountPart

**查询语句:**
```java
@SelectPart("SELECT DISTINCT u FROM User u LEFT JOIN FETCH u.groups g")
private boolean select = true;

@SelectCountPart("SELECT count(DISTINCT u) FROM User u LEFT JOIN u.groups g")
private boolean count = true;
```

**注意:** 计数查询不要使用 `FETCH JOIN`，会引发笛卡尔积。

## @OrderByPart

**排序:**
```java
@OrderByPart(direction = OrderByPart.Direction.DESC)
private String orderBy = "u.createdTime";
```

**Direction:**
- `ASC` - 升序
- `DESC` - 降序

## 字段规则

**自动跳过 null:**
- 字段值为 `null` → 不生成过滤条件
- Boolean 字段值为 `false` → 不生成过滤条件
- 字段值为空字符串 → 不生成过滤条件（除非指定 `filterValue`）

**使用 @Builder.Default:**
```java
@Builder.Default
@FilterPart(where = "u.status = :status")
private User.Status status = User.Status.ACTIVE;  // 默认值
```

## 完整示例

```java
@Builder
public class OrderCriteria extends AbstractCriteria {

    @Builder.Default
    @SelectPart("SELECT o FROM Order o WHERE o.deleted = false")
    private boolean select = true;

    @FilterPart(where = "o.orderNo LIKE :orderNo", pattern = MatchPattern.Left)
    private String orderNo;

    @FilterPart(where = "o.customer = :customer")
    private String customer;

    @FilterPart(where = "o.status in (:statuses)")
    public Set<Order.Status> statuses;

    @Builder.Default
    @OrderByPart(direction = Direction.DESC)
    private String orderBy = "o.createdTime";

    @Override
    protected void setupCollect() {
        // 预处理逻辑（如日期范围调整）
    }
}
```

**Service 使用:**
```java
public Page<Order> search(OrderCriteria criteria, Pageable pageable) {
    return find(Order.class, JpqlTokens.collect(criteria), pageable);
}
```