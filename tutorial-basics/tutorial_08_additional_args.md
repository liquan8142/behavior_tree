---
sidebar_position: 8
sidebar_label: 08. 传递附加参数
---

# 向你的节点传递附加参数

在我们迄今为止探索的每个示例中，我们都被"强制"提供具有以下签名的构造函数

``` cpp
MyCustomNode(const std::string& name, const NodeConfig& config);

```

在某些情况下，我们希望向类的构造函数传递附加参数、参数、指针、引用等。

:::caution
有些人使用黑板来做到这一点。 **不要** 这样做。
:::

在本教程的其余部分，我们将只使用_"参数"_这个词。

即使理论上这些参数 **可以** 使用输入端口传递，但在以下情况下，这将是错误的方式：

- 参数在_部署时_已知（当构建树时）。
- 参数在_运行时_不改变。
- 参数不需要从XML设置。

如果所有这些条件都满足，强烈不鼓励使用端口或黑板。

## 向构造函数添加参数（推荐）

考虑以下名为 **Action_A** 的自定义节点。

我们想要传递两个附加参数；它们可以是任意复杂的对象，你不限于内置类型。

``` cpp
// Action_A的构造函数与默认构造函数不同。
class Action_A: public SyncActionNode
{

public:
    // 传递给构造函数的附加参数
    Action_A(const std::string& name, const NodeConfig& config,
             int arg_int, std::string arg_str):
        SyncActionNode(name, config),
        _arg1(arg_int),
        _arg2(arg_str) {}

    // 此示例不需要任何端口
    static PortsList providedPorts() { return {}; }

    // tick()可以访问私有成员
    NodeStatus tick() override;

private:
    int _arg1;
    std::string _arg2;
};
```

注册此节点并传递已知参数非常简单：

``` cpp
BT::BehaviorTreeFactory factory;
factory.registerNodeType<Action_A>("Action_A", 42, "hello world");

// 如果你更喜欢指定模板参数
// factory.registerNodeType<Action_A, int, std::string>("Action_A", 42, "hello world");
```

## 使用"initialize"方法

如果由于任何原因，你需要向节点类型的各个实例传递不同的值，你可能需要考虑这种其他模式：

``` cpp
class Action_B: public SyncActionNode
{

public:
    // 构造函数看起来像往常一样。
    Action_B(const std::string& name, const NodeConfig& config):
        SyncActionNode(name, config) {}

    // 我们希望此方法在第一次tick()之前调用一次
    void initialize(int arg_int, const std::string& arg_str)
    {
        _arg1 = arg_int;
        _arg2 = arg_str;
    }

    // 此示例不需要任何端口
    static PortsList providedPorts() { return {}; }

    // tick()可以访问私有成员
    NodeStatus tick() override;

private:
    int _arg1;
    std::string _arg2;
};
```

我们注册和初始化Action_B的方式不同：

``` cpp
BT::BehaviorTreeFactory factory;

// 像往常一样注册，但我们仍然需要初始化
factory.registerNodeType<Action_B>("Action_B");

// 创建整个树。Action_B的实例尚未初始化
auto tree = factory.createTreeFromText(xml_text);

// visitor将初始化实例
auto visitor = [](TreeNode* node)
{
  if (auto action_B_node = dynamic_cast<Action_B*>(node))
  {
    action_B_node->initialize(69, "interesting_value");
  }
};

// 将visitor应用于树的所有节点
tree.applyVisitor(visitor);
```