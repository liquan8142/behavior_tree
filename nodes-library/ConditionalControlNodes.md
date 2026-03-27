---
sidebar_position: 5
sidebar_label: 条件控制节点
---

# 条件控制节点

这些控制节点根据条件（第一个子节点）的结果选择执行哪个子节点。

目前框架提供两种类型：

- IfThenElse
- WhileDoElse

两者都必须有 **2个或3个子节点** 。

## IfThenElse

IfThenElse是一个 **非响应式** 的条件节点。

- **第1个子节点** 是条件（"if"）。
- **第2个子节点** 在条件返回SUCCESS时执行（"then"）。
- **第3个子节点** （可选）在条件返回FAILURE时执行（"else"）。

如果只提供2个子节点且条件返回FAILURE，节点返回FAILURE（相当于以`AlwaysFailure`作为第3个子节点）。

条件 **只评估一次** 。如果第2个或第3个子节点返回RUNNING，条件在后续触发中 **不会** 重新评估。

```xml
<IfThenElse>
    <IsDoorOpen/>          <!-- 条件 -->
    <WalkThrough/>         <!-- then分支 -->
    <TryAnotherPath/>      <!-- else分支（可选） -->
</IfThenElse>
```

## WhileDoElse

WhileDoElse是IfThenElse的 **响应式** 变体。它在 **每次触发** 时重新评估条件。

- **第1个子节点** 是条件，在每次触发时评估（"while"）。
- **第2个子节点** 在条件返回SUCCESS时执行（"do"）。
- **第3个子节点** （可选）在条件返回FAILURE时执行（"else"）。

如果第2个或第3个子节点正在RUNNING且条件结果 **改变** ，则在切换到另一个分支之前，正在运行的子节点将被 **中止** 。

```xml
<WhileDoElse>
    <IsBatteryOK/>         <!-- 条件，每次触发重新评估 -->
    <ContinueMission/>     <!-- do分支 -->
    <GoToChargingStation/> <!-- else分支（可选） -->
</WhileDoElse>
```

## IfThenElse vs WhileDoElse

| 特性 | IfThenElse | WhileDoElse |
|---------|------------|-------------|
| 重新评估条件？ | 否 | 是（每次触发） |
| 响应式 | 否 | 是 |
| 条件改变时中止运行中的子节点？ | 不适用 | 是 |
| 用例 | 一次性分支 | 持续监控 |