---
sidebar_position: 3
sidebar_label: 03. 通用类型端口
---

# 通用类型端口

在前面的教程中，我们介绍了输入和输出端口，其中
端口的类型是`std::string`。

接下来，我们将展示如何为你的端口分配通用的C++类型。

## 解析字符串

__BehaviorTree.CPP__ 支持将字符串自动转换为常见的
类型，如`int`、`long`、`double`、`bool`、`NodeStatus`等。
用户定义的类型也可以轻松支持。

例如：

``` cpp
// 我们想要使用这个自定义类型
struct Position2D 
{ 
  double x;
  double y; 
};
```

为了让XML加载器能够从字符串实例化`Position2D`，
我们需要提供`BT::convertFromString<Position2D>(StringView)`的模板特化。

`Position2D`如何序列化为字符串由你决定；在这种情况下，
我们简单地用_分号_分隔两个数字。

``` cpp
// 将字符串转换为Position2D的模板特化。
namespace BT
{
    template <> inline Position2D convertFromString(StringView str)
    {
        // 我们期望用分号分隔的实数
        auto parts = splitString(str, ';');
        if (parts.size() != 2)
        {
            throw RuntimeError("invalid input)");
        }
        else
        {
            Position2D output;
            output.x     = convertFromString<double>(parts[0]);
            output.y     = convertFromString<double>(parts[1]);
            return output;
        }
    }
} // end namespace BT
```

- `StringView`是[std::string_view](https://en.cppreference.com/w/cpp/header/string_view)的C++11版本。
   你可以传递`std::string`或`const char*`。
- 库提供了一个简单的`splitString`函数。可以随意使用另一个，
   如[boost::algorithm::split](https://www.boost.org/doc/libs/1_80_0/doc/html/boost/algorithm/split.html)。
- 我们可以使用特化`convertFromString<double>()`。  
   
## 示例

正如我们在上一个教程中所做的那样，我们可以创建两个自定义动作，
一个将写入端口，另一个将从端口读取。

``` cpp
class CalculateGoal: public SyncActionNode
{
  public:
    CalculateGoal(const std::string& name, const NodeConfig& config):
      SyncActionNode(name,config)
    {}

    static PortsList providedPorts()
    {
      return { OutputPort<Position2D>("goal") };
    }

    NodeStatus tick() override
    {
      Position2D mygoal = {1.1, 2.3};
      setOutput<Position2D>("goal", mygoal);
      return NodeStatus::SUCCESS;
    }
};

class PrintTarget: public SyncActionNode
{
  public:
    PrintTarget(const std::string& name, const NodeConfig& config):
        SyncActionNode(name,config)
    {}

    static PortsList providedPorts()
    {
      // 可选地，端口可以有一个人类可读的描述
      const char*  description = "Simply print the goal on console...";
      return { InputPort<Position2D>("target", description) };
    }
      
    NodeStatus tick() override
    {
      auto res = getInput<Position2D>("target");
      if( !res )
      {
        throw RuntimeError("error reading port [target]:", res.error());
      }
      Position2D target = res.value();
      printf("Target positions: [ %.1f, %.1f ]\n", target.x, target.y );
      return NodeStatus::SUCCESS;
    }
};
```   

我们现在可以像往常一样连接输入/输出端口，指向黑板的同一个条目。

下一个示例中的树是一个包含4个动作的序列：

- 使用动作`CalculateGoal`在条目__GoalPosition__中存储`Position2D`的值。

- 调用`PrintTarget`。输入"target"将从黑板条目__GoalPosition__读取。

- 使用内置动作`Script`将字符串"-1;3"分配给键__OtherGoal__。
  从字符串到`Position2D`的转换将自动完成。

- 再次调用`PrintTarget`。输入"target"将从条目__OtherGoal__读取。

``` cpp  
static const char* xml_text = R"(

 <root BTCPP_format="4" >
     <BehaviorTree ID="MainTree">
        <Sequence name="root">
            <CalculateGoal goal="{GoalPosition}" />
            <PrintTarget   target="{GoalPosition}" />
            <Script        code=" OtherGoal:='-1;3' " />
            <PrintTarget   target="{OtherGoal}" />
        </Sequence>
     </BehaviorTree>
 </root>
 )";

int main()
{
  BT::BehaviorTreeFactory factory;
  factory.registerNodeType<CalculateGoal>("CalculateGoal");
  factory.registerNodeType<PrintTarget>("PrintTarget");

  auto tree = factory.createTreeFromText(xml_text);
  tree.tickWhileRunning();

  return 0;
}
/* 预期输出：

    Target positions: [ 1.1, 2.3 ]
    Converting string: "-1;3"
    Target positions: [ -1.0, 3.0 ]
*/
```  






   
