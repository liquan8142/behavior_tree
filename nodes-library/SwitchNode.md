---
sidebar_position: 6
sidebar_label: 切换节点
---

# 切换节点

SwitchNode等同于`switch`语句：它根据黑板变量的值选择执行哪个子节点。

可用变体：`Switch2`、`Switch3`、`Switch4`、`Switch5`、`Switch6`，其中数字表示支持多少个case分支。

SwitchN节点必须有**N + 1个子节点 **：N个case分支加上一个** 默认**分支（总是最后一个子节点）。

| 端口 | 类型 | 描述 |
|------|------|-------------|
| `variable` | InputPort\<string\> | 与case比较的黑板变量。 |
| `case_1` | InputPort\<string\> | 与第1个子节点匹配的值。 |
| `case_2` | InputPort\<string\> | 与第2个子节点匹配的值。 |
| ... | ... | 最多N个附加case。 |

`variable`值按顺序与每个`case_N`字符串比较。执行与第一个匹配对应的子节点。如果没有case匹配，执行 **最后一个子节点** （默认分支）。

比较支持字符串、整数和双精度浮点数。通过`ScriptingEnumsRegistry`注册的枚举值也受支持。

```xml
<Switch3 variable="{robot_state}" case_1="IDLE" case_2="WORKING" case_3="ERROR">
    <HandleIdle/>          <!-- 当robot_state == "IDLE"时执行 -->
    <HandleWorking/>       <!-- 当robot_state == "WORKING"时执行 -->
    <HandleError/>         <!-- 当robot_state == "ERROR"时执行 -->
    <HandleUnknownState/>  <!-- 默认：当没有case匹配时执行 -->
</Switch3>
```

如果先前匹配的子节点正在RUNNING，并且`variable`值在后续触发中更改，则在执行新匹配的子节点之前，正在运行的子节点被 **中止** 。

:::tip
可以使用多个Sequence、Fallback和Condition实现相同的行为，但Switch更简洁和可读。
:::