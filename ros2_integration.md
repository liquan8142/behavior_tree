---
sidebar_position: 6
---

# 与ROS2集成

BehaviorTree.CPP经常用于机器人和[ROS](https://docs.ros.org/en/humble/index.html)生态系统。

我们提供了一套现成的包装器，可用于快速实现与ROS2交互的TreeNodes：[BehaviorTree.ROS2](https://github.com/BehaviorTree/BehaviorTree.ROS2)

在系统架构方面，我们应该记住：

- 你应该有一个集中式的"协调器"ROS节点，负责行为的执行。这将进一步称为"任务规划器"，它将使用BT.CPP实现。

- 系统的所有其他元素应该是"面向服务"的组件，并应将任何业务逻辑和决策委托给任务规划器。

:::caution
有些词相同，但在 **ROS** 或 **BT.CPP** 的上下文中有不同的含义。

特别是，单词"Action"和"Node"：

- `TreeNode` vs `rclcpp::Node`
- `BT::Action` vs `rclcpp_action`。
:::

你可以直接使用它们，或使用它们作为模板/蓝图来创建你自己的。

## 使用rclcpp_action的异步BT::Action

与ROS交互的推荐方式是通过[rclcpp_action](https://docs.ros.org/en/humble/Tutorials/Intermediate/Writing-an-Action-Server-Client/Cpp.html)。

它们是完美的匹配，因为：

- 它们的API是异步的，即用户不应担心创建单独的线程。

- 它们可以被中止，这是实现`TreeNode::halt()`和构建响应式行为所需的功能。

例如，让我们考虑[官方C++教程](https://docs.ros.org/en/humble/Tutorials/Intermediate/Writing-an-Action-Server-Client/Cpp.html#writing-an-action-client)中描述的"Fibonacci"动作客户端。

要创建调用此ROS动作的BT动作：

```cpp
#include <behaviortree_ros2/bt_action_node.hpp>
#include "action_tutorials_interfaces/action/fibonacci.hpp"

// 为简洁起见，定义这些
using Fibonacci = action_tutorials_interfaces::action::Fibonacci;
using GoalHandleFibonacci = rclcpp_action::ServerGoalHandle<Fibonacci>;

using namespace BT;

class FibonacciAction: public RosActionNode<Fibonacci>
{
public:
  FibonacciAction(const std::string& name,
                  const NodeConfig& conf,
                  const RosNodeParams& params)
    : RosActionNode<Fibonacci>(name, conf, params)
  {}

  // 此派生类的特定端口
  // 应与基类的端口合并，
  // 使用RosActionNode::providedBasicPorts()
  static PortsList providedPorts()
  {
    return providedBasicPorts({InputPort<unsigned>("order")});
  }

  // 当TreeNode被触发时调用，它应该
  // 向动作服务器发送请求
  bool setGoal(RosActionNode::Goal& goal) override 
  {
    // 从输入端口获取"order"
    getInput("order", goal.order);
    // 如果能够正确设置目标，返回true。
    return true;
  }
  
  // 收到回复时执行的回调。
  // 根据回复，你可以决定返回SUCCESS或FAILURE。
  NodeStatus onResultReceived(const WrappedResult& wr) override
  {
    std::stringstream ss;
    ss << "Result received: ";
    for (auto number : wr.result->sequence) {
      ss << number << " ";
    }
    RCLCPP_INFO(logger(), ss.str().c_str());
    return NodeStatus::SUCCESS;
  }

  // 当客户端和服务器之间的通信级别
  // 出现错误时调用的回调。
  // 这将根据返回值将TreeNode的状态设置为SUCCESS或FAILURE。
  // 如果不重写，默认返回FAILURE。
  virtual NodeStatus onFailure(ActionNodeErrorCode error) override
  {
    RCLCPP_ERROR(logger(), "Error: %d", error);
    return NodeStatus::FAILURE;
  }

  // 我们也支持反馈回调，如
  // 原始教程中所示。
  // 通常，此回调应返回RUNNING，但你可以
  // 根据反馈的值决定中止
  // 动作，并认为TreeNode已完成。
  // 在这种情况下，返回SUCCESS或FAILURE。
  // 取消请求将自动发送到服务器。
  NodeStatus onFeedback(const std::shared_ptr<const Feedback> feedback)
  {
    std::stringstream ss;
    ss << "Next number in sequence received: ";
    for (auto number : feedback->partial_sequence) {
      ss << number << " ";
    }
    RCLCPP_INFO(logger(), ss.str().c_str());
    return NodeStatus::RUNNING;
  }
};
```

你可能注意到BT版本的Action客户端比原始版本更简单，因为大多数样板代码都在`BT::RosActionNode`包装器内部。

注册此节点时，我们需要使用`BT::RosNodeParams`传递`rclcpp::Node`和其他参数：

```cpp
  // 在main()中
  BehaviorTreeFactory factory;

  auto node = std::make_shared<rclcpp::Node>("fibonacci_action_client");
  // 提供ROS节点和动作服务的名称
  RosNodeParams params; 
  params.nh = node;
  params.default_port_value = "fibonacci";
  factory.registerNodeType<FibonacciAction>("Fibonacci", params);
```

## 使用rclcpp::Client（服务）的异步BT::Action

ROS服务客户端也有类似的包装器。将使用异步接口。

下面的示例基于[官方教程](https://docs.ros.org/en/humble/Tutorials/Beginner-Client-Libraries/Writing-A-Simple-Cpp-Service-And-Client.html#write-the-client-node)。

```cpp
#include <behaviortree_ros2/bt_service_node.hpp>
#include "example_interfaces/srv/add_two_ints.hpp"

using AddTwoInts = example_interfaces::srv::AddTwoInts;
using namespace BT;


class AddTwoIntsNode: public RosServiceNode<AddTwoInts>
{
  public:

  AddTwoIntsNode(const std::string& name,
                  const NodeConfig& conf,
                  const RosNodeParams& params)
    : RosServiceNode<AddTwoInts>(name, conf, params)
  {}

  // 此派生类的特定端口
  // 应与基类的端口合并，
  // 使用RosServiceNode::providedBasicPorts()
  static PortsList providedPorts()
  {
    return providedBasicPorts({
        InputPort<unsigned>("A"),
        InputPort<unsigned>("B")});
  }

  // 当TreeNode被触发时调用，它应该
  // 向服务提供者发送请求
  bool setRequest(Request::SharedPtr& request) override
  {
    // 使用输入端口设置A和B
    getInput("A", request->a);
    getInput("B", request->b);
    // 如果准备好发送请求，必须返回true
    return true;
  }

  // 收到答案时调用的回调。
  // 必须返回SUCCESS或FAILURE
  NodeStatus onResponseReceived(const Response::SharedPtr& response) override
  {
    RCLCPP_INFO(logger(), "Sum: %ld", response->sum);
    return NodeStatus::SUCCESS;
  }

  // 当客户端和服务器之间的通信级别
  // 出现错误时调用的回调。
  // 这将根据返回值将TreeNode的状态设置为SUCCESS或FAILURE。
  // 如果不重写，默认返回FAILURE。
  virtual NodeStatus onFailure(ServiceNodeErrorCode error) override
  {
    RCLCPP_ERROR(logger(), "Error: %d", error);
    return NodeStatus::FAILURE;
  }
};
```