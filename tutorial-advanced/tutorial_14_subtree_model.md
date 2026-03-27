---
sidebar_position: 14
sidebar_label: 14. 子树模型与自动重映射
---

# 子树模型与自动重映射

子树重映射在[教程6](../tutorial-basics/tutorial_06_subtree_ports.md)中介绍过。

不幸的是，当在多个位置使用相同的子树时，我们可能会发现自己复制和粘贴相同的长XML标签。

例如，考虑这样的情况：

```xml
<SubTree ID="MoveRobot" target="{move_goal}"  frame="world" result="{error_code}" />
```

我们不想每次都复制和粘贴三个XML属性`target`、`frame`和`result`，除非它们的值确实不同。

为了避免这种情况，我们可以在`<TreeNodesModel>`中定义它们的默认值。

```xml
  <TreeNodesModel>
    <SubTree ID="MoveRobot">
      <input_port  name="target"  default="{move_goal}"/>
      <input_port  name="frame"   default="world"/>
      <output_port name="result"  default="{error_code}"/>
    </SubTree>
  </TreeNodesModel>
```
从概念上讲，这类似于[教程12](tutorial-advanced/tutorial_12_default_ports.md)中解释的默认端口。

如果在XML中指定，这些重映射的黑板条目的值将被覆盖。在下面的示例中，我们覆盖了"frame"的值，但保持其他默认重映射。

```xml
<SubTree ID="MoveRobot" frame="map" />
```

## 自动重映射

当子树和父树中的条目名称**相同**时，你可以使用属性`_autoremap`。

例如：

```xml
<SubTree ID="MoveRobot" target="{target}"  frame="{frame}" result="{result}" />
```

可以替换为：
```xml
<SubTree ID="MoveRobot" _autoremap="true" />
```

我们仍然可以覆盖特定的值，并自动重映射其他值

```xml
<SubTree ID="MoveRobot" _autoremap="true" frame="world" />
```

:::caution
属性`_autoremap="true"`将自动重映射子树中的**所有**条目，**除非**它们的名称以下划线（字符"_"）开头。

这可能是将子树中的条目标记为"私有"的便捷方式。
:::