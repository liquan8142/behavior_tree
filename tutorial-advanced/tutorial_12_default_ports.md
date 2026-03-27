---
sidebar_position: 12
sidebar_label: 12. 默认端口值
---

# 默认端口值

在定义端口时，添加默认值可能很方便，即如果XML中未指定，端口应具有的值。

:::note
本教程中显示的一些示例需要版本4.5.2或更高版本。
:::

## 默认输入端口

让我们考虑一个初始化多个端口的节点。我们使用自定义类型**Point2D**，但对于简单类型（如`int`、`double`或`string`）也是如此。

```cpp
  static PortsList providedPorts()
  {
    return { 
      BT::InputPort<Point2D>("input"),
      BT::InputPort<Point2D>("pointA", Point2D{1, 2}, "默认值是 x=1, y=2"),
      BT::InputPort<Point2D>("pointB", "3,4",         "默认值是 x=3, y=4"),
      BT::InputPort<Point2D>("pointC", "{point}",     "默认指向黑板条目 {point}"),
      BT::InputPort<Point2D>("pointD", "{=}",         "默认指向黑板条目 {pointD}") 
    };
  }
```

第一个（`input`）没有默认值，必须在XML中提供值或黑板条目。

### 默认值

```cpp
BT::InputPort<Point2D>("pointA", Point2D{1, 2}, "...");
```

如果实现了模板特化`convertFromString<Point2D>()`，我们也可以使用它。

换句话说，如果我们的**convertFromString**期望两个逗号分隔的值，以下语法应该是等价的：

```cpp
BT::InputPort<Point2D>("pointB", "3,4", "...");
// 应该等同于：
BT::InputPort<Point2D>("pointB", Point2D{3, 4}, "...");
```

### 默认黑板条目

或者，我们可以定义端口应指向的默认黑板条目。

```cpp
BT::InputPort<Point2D>("pointC", "{point}", "...");
```

如果端口名称和黑板条目名称**相同**，你可以使用`"{=}"`

```cpp
BT::InputPort<Point2D>("pointD", "{=}", "...");
// 等同于：
BT::InputPort<Point2D>("pointD", "{pointD}", "...");
```

## 默认输出端口

输出端口更有限，只能指向黑板条目。当两个名称相同时，你仍然可以使用`"{=}"`。

```cpp
  static PortsList providedPorts()
  {
    return { 
      BT::OutputPort<Point2D>("result", "{target}", "默认指向黑板条目 {target}");
    };
  }
```