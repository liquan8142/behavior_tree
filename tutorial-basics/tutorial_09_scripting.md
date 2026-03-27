---
sidebar_position: 9
sidebar_label: 09. 脚本示例
---

# 脚本语言介绍

更详细的描述可以在[脚本介绍](guides/scripting.md)中找到。
本教程提供了一个非常基础的示例，你可以将其用作初始的试验场。

## Script和Precondition节点

在我们的脚本语言中，变量是黑板中的条目。

在这个示例中，我们使用**Script**节点来设置这些变量，并观察我们如何在**SaySomething**中作为输入端口访问它们。

支持的类型包括数字（整数和实数）、字符串和注册的ENUM。

:::caution
注意我们使用**magic_enums**，它有一些已知的[限制](https://github.com/Neargye/magic_enum/blob/master/doc/limitations.md)。

一个显著的限制是默认范围是[-128, 128]，除非按照上面链接中的描述进行更改。
:::

我们将使用这个XML：

```xml
<root BTCPP_format="4">
  <BehaviorTree>
    <Sequence>
      <Script code=" msg:='hello world' " />
      <Script code=" A:=THE_ANSWER; B:=3.14; color:=RED " />
      <Precondition if="A>B && color != BLUE" else="FAILURE">
        <Sequence>
          <SaySomething message="{A}"/>
          <SaySomething message="{B}"/>
          <SaySomething message="{msg}"/>
          <SaySomething message="{color}"/>
        </Sequence>
      </Precondition>
    </Sequence>
  </BehaviorTree>
</root>
```

我们期望以下黑板条目包含：

- **msg**：字符串"hello world"
- **A**：对应于别名THE_ANSWER的整数值。
- **B**：实数值3.14
- **C**：对应于枚举RED的整数值。

因此，预期输出是：

```console
Robot says: 42.000000
Robot says: 3.140000
Robot says: hello world
Robot says: 1.000000
```

C++代码是：

```cpp
enum Color
{
  RED = 1,
  BLUE = 2,
  GREEN = 3
};

int main()
{
  BehaviorTreeFactory factory;
  factory.registerNodeType<DummyNodes::SaySomething>("SaySomething");

  // 我们可以将这些枚举添加到脚本语言中。
  // 检查magic_enum的限制
  factory.registerScriptingEnums<Color>();

  // 或者我们可以手动为标签"THE_ANSWER"分配一个数字。
  // 这不受任何范围限制的影响
  factory.registerScriptingEnum("THE_ANSWER", 42);

  auto tree = factory.createTreeFromText(xml_text);
  tree.tickWhileRunning();

  return 0;
}
```