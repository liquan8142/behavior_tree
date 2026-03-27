---
sidebar_position: 4
sidebar_label: 并行节点
---

# 并行节点

并行节点**并发**执行其所有子节点，但**不在**单独的线程中。所有子节点在树的单次触发中按顺序触发，多个子节点可能同时处于RUNNING状态。

:::caution
"并行"指的是多个子节点可以**并发**处于RUNNING状态。子节点仍在同一线程内按顺序触发。对于实际的多线程执行，子节点内部必须是异步节点。
:::

目前框架提供两种类型的节点：

- Parallel
- ParallelAll

并行节点是**唯一**可以有多个子节点同时处于RUNNING状态的节点。

## Parallel

当达到SUCCESS或FAILURE阈值时完成。任何剩余的运行中子节点被中止。

| 端口 | 类型 | 默认值 | 描述 |
|------|------|---------|-------------|
| `success_count` | InputPort\<int\> | -1 | 必须成功以返回SUCCESS的子节点数量。 |
| `failure_count` | InputPort\<int\> | 1 | 必须失败以返回FAILURE的子节点数量。 |

阈值值支持**Python风格的负索引**：`-1`等同于子节点总数。例如，有4个子节点时，`success_count="-1"`意味着所有4个都必须成功。

**默认行为** (success_count=-1, failure_count=1)：所有子节点必须成功；如果任何单个子节点失败，节点返回FAILURE。

```xml
<Parallel success_count="2" failure_count="2">
    <ActionA/>
    <ActionB/>
    <ActionC/>
</Parallel>
```

在这个有3个子节点的示例中：
- 如果2个子节点返回SUCCESS（在2个失败之前），节点返回SUCCESS。
- 如果2个子节点返回FAILURE（在2个成功之前），节点返回FAILURE。
- 当达到任一阈值时，剩余的RUNNING子节点被中止。

## ParallelAll

与Parallel不同，ParallelAll节点**总是执行所有子节点直到完成**。它从不提前中止子节点。当你需要所有副作用都完成时，这很有用。

| 端口 | 类型 | 默认值 | 描述 |
|------|------|---------|-------------|
| `max_failures` | InputPort\<int\> | 1 | 返回FAILURE之前允许的最大子节点失败数。 |

- 如果FAILURE数量**小于**`max_failures`，返回**SUCCESS**。
- 如果FAILURE数量**等于或超过**`max_failures`，返回**FAILURE**。
- 使用`max_failures="-1"`（子节点数量）以始终返回SUCCESS，无论子节点结果如何。

```xml
<ParallelAll max_failures="2">
    <ActionA/>
    <ActionB/>
    <ActionC/>
</ParallelAll>
```

## Parallel vs ParallelAll

| 特性 | Parallel | ParallelAll |
|---------|----------|-------------|
| 提前终止 | 是（达到阈值时中止子节点） | 否（总是运行所有子节点） |
| 成功阈值 | 可配置（`success_count`） | 所有未失败的子节点 |
| 失败阈值 | 可配置（`failure_count`） | 可配置（`max_failures`） |
| 用例 | 竞争条件，N-of-M成功 | 所有任务必须尝试完成 |