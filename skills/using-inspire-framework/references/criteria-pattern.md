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

List<JpqlToken> tokens = criteria.tokens();  // 经 AbstractCriteria 入口触发 setupCollect()/afterTokens()
List<User> users = find(User.class, tokens);
```

## @FilterPart 注解

**属性:**
- `where`（别名 `value`）- JPQL WHERE 子句，使用命名参数（默认参数名 = 字段名，可用 `name` 覆盖）
- `pattern` - LIKE 匹配模式（可选）
- `name` - 命名参数名（默认使用字段名）
- `filterValue` - 布尔字段为 `true` 时使用的固定过滤值
- `filterValueType` - `filterValue` 的解析类型（默认 `String`）

**MatchPattern 模式:**
- `None` - 不添加通配符，原值匹配
- `Left` - 左匹配，添加 `%` 在右侧（`value%`）
- `Right` - 右匹配，添加 `%` 在左侧（`%value`）
- `FullText` - 全文匹配，前后添加 `%`（`%value%`）

**自动转义:**
`Left`/`Right`/`FullText` 模式会自动转义值中的 LIKE 通配符 `%` 和 `_` 为 `\%` 和 `\_`，并在生成的 JPQL 中追加 `ESCAPE '\'`。

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

**条件生成:**
- 字段值为 `null` → 所有注解都不生成条件
- Boolean 字段值为 `false` → `@SelectPart`/`@SelectCountPart`/`@GroupByPart` 不生成条件；`@FilterPart` 不受此规则影响
- 字段值为空字符串 → 仅 `@FilterPart` 且 `pattern` 非 `None` 时自动跳过（避免 `%%`）；未指定 `pattern` 时按普通值生成条件，空值会导致参数未绑定，建议自行判空

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

    @FilterPart(where = "o.orderNo LIKE :orderNo", pattern = FilterPart.MatchPattern.Left)
    private String orderNo;

    @FilterPart(where = "o.customer = :customer")
    private String customer;

    @FilterPart(where = "o.status in (:statuses)")
    public Set<Order.Status> statuses;

    @Builder.Default
    @OrderByPart(direction = OrderByPart.Direction.DESC)
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
    return find(Order.class, criteria.tokens(), pageable);
}
```