---
sidebar_position: 15
sidebar_label: 15. 模拟与节点替换
---

# BT.CPP中的模拟测试

有时，特别是在实现集成测试和单元测试时，我们希望有一种机制允许我们快速将特定节点或整个节点类替换为"测试"版本（模拟）。

自版本4.1起，我们引入了一种称为"替换规则"的新机制，使这个过程更容易。

它由`BehaviorTreeFactory`类中的附加方法组成，这些方法应该在节点注册**之后**、实际树实例化**之前**调用。

例如，给定XML：

```xml
<SaySomething name="talk" message="hello world"/>
```
我们可能希望将此节点替换为另一个名为**TestMessage**的节点：

相应的替换通过以下命令完成：

```cpp
factory.addSubstitutionRule("talk", "TestMessage");
```

第一个参数包含将与`TreeNode::fullPath`匹配的[通配符字符串](https://en.wikipedia.org/wiki/Wildcard_character)。

有关**fullPath**的详细信息，请查看[上一个教程](tutorial-basics/tutorial_10_observer.md)。

## TestNode

`TestNode`是一个可以配置为以下操作的动作：

- 返回特定状态，SUCCESS或FAILURE
- 同步或异步；在后一种情况下，应指定超时。
- 后置条件脚本，通常用于模拟OutputPort。

这个简单的虚拟节点不会覆盖100%的情况，但可以作为许多替换规则的默认解决方案。

## 完整示例

在这个示例中，我们将看到：

- 如何使用替换规则将一个节点替换为另一个节点。
- 如何使用内置的`TestNode`。
- 通配符匹配的示例。
- 如何在运行时使用JSON文件传递这些规则。

我们将使用这个XML：

```xml
<root BTCPP_format="4">
  <BehaviorTree ID="MainTree">
    <Sequence>
      <SaySomething name="talk" message="hello world"/>
        <Fallback>
          <AlwaysFailure name="failing_action"/>
          <SubTree ID="MySub" name="mysub"/>
        </Fallback>
        <SaySomething message="before last_action"/>
        <Script code="msg:='after last_action'"/>
        <AlwaysSuccess name="last_action"/>
        <SaySomething message="{msg}"/>
    </Sequence>
  </BehaviorTree>

  <BehaviorTree ID="MySub">
    <Sequence>
      <AlwaysSuccess name="action_subA"/>
      <AlwaysSuccess name="action_subB"/>
    </Sequence>
  </BehaviorTree>
</root>
```

C++代码：

```cpp
int main(int argc, char** argv)
{
  BT::BehaviorTreeFactory factory;
  factory.registerNodeType<SaySomething>("SaySomething");

  // 我们使用lambda和registerSimpleAction来创建
  // 一个"虚拟"节点，我们想用它替换给定的节点。

  // 简单节点，只打印其名称并返回SUCCESS
  factory.registerSimpleAction("DummyAction", [](BT::TreeNode& self){
    std::cout << "DummyAction substituting: "<< self.name() << std::endl;
    return BT::NodeStatus::SUCCESS;
  });

  // 旨在替换SaySomething的动作。
  // 它将尝试使用输入端口"message"
  factory.registerSimpleAction("TestSaySomething", [](BT::TreeNode& self){
    auto msg = self.getInput<std::string>("message");
    if (!msg)
    {
      throw BT::RuntimeError( "missing required input [message]: ", msg.error() );
    }
    std::cout << "TestSaySomething: " << msg.value() << std::endl;
    return BT::NodeStatus::SUCCESS;
  });

  //----------------------------
  // 传递"no_sub"作为第一个参数以避免添加规则
  bool skip_substitution = (argc == 2) && std::string(argv[1]) == "no_sub";

  if(!skip_substitution)
  {
    // 我们可以使用JSON文件来配置替换规则
    // 或手动完成
    bool const USE_JSON = true;

    if(USE_JSON)
    {
      factory.loadSubstitutionRuleFromJSON(json_text);
    }
    else {
      // 将匹配此通配符模式的节点替换为TestAction
      factory.addSubstitutionRule("mysub/action_*", "TestAction");

      // 将名为[talk]的节点替换为TestSaySomething
      factory.addSubstitutionRule("talk", "TestSaySomething");

      // 此配置将传递给TestNode
      BT::TestNodeConfig test_config;
      // 将节点转换为异步并等待2000毫秒
      test_config.async_delay = std::chrono::milliseconds(2000);
      // 完成后执行此后置条件
      test_config.post_script = "msg ='message SUBSTITUED'";

      // 将名为[last_action]的节点替换为TestNode，
      // 使用test_config配置
      factory.addSubstitutionRule("last_action", test_config);
    }
  }

  factory.registerBehaviorTreeFromText(xml_text);

  // 在树的构造阶段，替换
  // 规则将用于实例化测试节点，而不是
  // 原始节点。
  auto tree = factory.createTree("MainTree");
  tree.tickWhileRunning();

  return 0;
}
```

## JSON格式

当`USE_JSON == false`时执行的等效JSON文件是：

```json
{
  "TestNodeConfigs": {
    "MyTest": {
      "async_delay": 2000,
      "return_status": "SUCCESS",
      "post_script": "msg ='message SUBSTITUED'"
    }
  },

  "SubstitutionRules": {
    "mysub/action_*": "TestAction",
    "talk": "TestSaySomething",
    "last_action": "MyTest"
  }
}
```

如你所见，有两个主要部分：

- **TestNodeConfigs**，设置一个或多个**TestNode**的参数和名称。

- **SubstitutionRules**，指定实际的规则。