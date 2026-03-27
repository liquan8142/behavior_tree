# 主要概念

__BehaviorTree.CPP__ 是一个C++库，可以轻松集成到你喜欢的分布式中间件中，例如 __ROS__ 或 __SmartSoft__ 。

你可以将其静态链接到你的应用程序中（例如游戏）。

这些是你首先需要理解的主要概念。

## 节点 vs 树

用户必须创建自己的动作节点和条件节点（叶节点）；这个库帮助你轻松地将它们组合成树。

将叶节点视为构建复杂系统所需的构建块。如果节点是 **乐高积木** ，那么你的树就是乐高套装。

![](images/lego.jpg) 

根据定义，你的自定义节点是（或应该是）高度 __可重用__ 的。

## 使用XML格式在运行时实例化树

尽管库是用C++编写的，但树本身可以在_运行时_创建和组合，更具体地说，在 _部署时_ 使用基于XML的脚本语言。

XML格式在[这里](xml_format.md)详细描述，但学习语法的最佳方式是遵循教程。

## tick()回调

任何TreeNode都可以被视为调用 __回调__ 的机制，即 __运行一段代码__ 。这个回调做什么取决于你。

在大多数以下教程中，我们的动作将简单地在控制台上打印消息或休眠一定时间以模拟长时间计算。

在生产代码中，特别是在模型驱动开发和基于组件的软件工程中，动作/条件可能会与系统的其他 _组件_ 或 _服务_ 通信。

``` cpp
// 你可以包装到BT动作中的最简单回调
NodeStatus HelloTick()
{
  std::cout << "Hello World\n"; 
  return NodeStatus::SUCCESS;
}

// 允许库创建调用HelloTick()的动作
//（在教程中解释）
factory.registerSimpleAction("Hello", std::bind(HelloTick));
```

> [!TIP]
> 
> 
> 工厂可以创建节点 __Hello__ 的多个实例。

## 通过继承创建自定义节点

在上面的示例中，使用__函数指针__（依赖注入）创建了调用`HelloTick`的特定类型的TreeNodes。

通常，要定义自定义TreeNode，你应该继承自`TreeNode`类，或者更具体地说，它的派生类：

- `ActionNodeBase`
- `ConditionNode`
- `DecoratorNode`

作为参考，请查看[第一个教程](tutorial-basics/tutorial_01_first_tree.md)。

## 数据流、端口和黑板

端口在[第二个](tutorial-basics/tutorial_02_basic_ports.md)和[第三个](tutorial-basics/tutorial_03_generic_ports.md)教程中详细解释。

目前，重要的是要知道：

- __黑板__ 是树的所有节点共享的 _键/值_ 存储。

- __端口__ 是节点可以用来相互交换信息的机制。
 
- 端口使用黑板的相同_键_"连接"。

- 节点的端口数量、名称和类型必须在_编译时_（C++）已知；端口之间的连接在_部署时_（XML）完成。

- 你可以存储任何C++类型作为值（我们使用类似于[std::any](https://www.fluentcpp.com/2021/02/05/how-stdany-works/)的_类型擦除_技术）。