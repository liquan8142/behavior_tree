---
sidebar_position: 4
sidebar_label: 04. 响应式行为
---

# 响应式与异步行为

下一个示例展示了`SequenceNode`和`ReactiveSequence`之间的区别。

我们将实现一个 __异步动作__ ，即一个需要很长时间才能完成，并且在完成条件未满足时返回RUNNING的动作。

异步动作具有以下要求：

- 它不应在`tick()`方法中阻塞太长时间。执行流应尽快返回。

- 如果调用`halt()`方法，它应尽快中止。

:::caution 
### 了解更多关于异步动作

用户应充分理解BT.CPP中如何实现并发，并学习开发自己的异步动作的最佳实践。你可以在[这里](guides/asynchronous_nodes.md)找到一篇详细的文章。
:::

## StatefulActionNode

__StatefulActionNode__ 是实现异步动作的首选方式。

当你的代码包含 __请求-回复模式__ 时，它特别有用，即当动作向另一个进程发送异步请求，并定期检查是否已收到回复时。

基于该回复，它可能返回SUCCESS或FAILURE。

如果你不是在与外部进程通信，而是在执行一些需要很长时间的计算，你可能希望将其拆分为小的"块"，或者你可能希望将该计算移动到另一个线程（参见[AsyncThreadedAction](guides/asynchronous_nodes.md)教程）。

__StatefulActionNode__的派生类必须重写以下虚方法，而不是`tick()`：

- `NodeStatus onStart()`：当节点处于IDLE状态时调用。它可能立即成功或失败，或返回RUNNING。在后一种情况下，下次收到触发信号时，将执行`onRunning`方法。

- `NodeStatus onRunning()`：当节点处于RUNNING状态时调用。返回新的状态。

- `void onHalted()`：当此节点被树中的另一个节点中止时调用。

让我们创建一个名为 __MoveBaseAction__ 的虚拟节点：

``` cpp
// 自定义类型
struct Pose2D
{
    double x, y, theta;
};

namespace chr = std::chrono;

class MoveBaseAction : public BT::StatefulActionNode
{
  public:
    // 任何带有端口的TreeNode必须具有此签名的构造函数
    MoveBaseAction(const std::string& name, const BT::NodeConfig& config)
      : StatefulActionNode(name, config)
    {}

    // 必须定义此静态方法。
    static BT::PortsList providedPorts()
    {
        return{ BT::InputPort<Pose2D>("goal") };
    }

    // 此函数在开始时调用一次。
    BT::NodeStatus onStart() override;

    // 如果onStart()返回RUNNING，我们将继续调用
    // 此方法，直到它返回不同于RUNNING的值
    BT::NodeStatus onRunning() override;

    // 如果动作被另一个节点中止，则执行的回调
    void onHalted() override;

  private:
    Pose2D _goal;
    chr::system_clock::time_point _completion_time;
};

//-------------------------

BT::NodeStatus MoveBaseAction::onStart()
{
  if ( !getInput<Pose2D>("goal", _goal))
  {
    throw BT::RuntimeError("missing required input [goal]");
  }
  printf("[ MoveBase: SEND REQUEST ]. goal: x=%f y=%f theta=%f\n",
         _goal.x, _goal.y, _goal.theta);

  // 我们使用此计数器模拟一个需要一定时间
  // 才能完成的动作（200毫秒）
  _completion_time = chr::system_clock::now() + chr::milliseconds(220);

  return BT::NodeStatus::RUNNING;
}

BT::NodeStatus MoveBaseAction::onRunning()
{
  // 假装我们正在检查是否已收到回复
  // 你不想在此函数内阻塞太长时间。
  std::this_thread::sleep_for(chr::milliseconds(10));

  // 假装经过一定时间后，
  // 我们已完成操作
  if(chr::system_clock::now() >= _completion_time)
  {
    std::cout << "[ MoveBase: FINISHED ]" << std::endl;
    return BT::NodeStatus::SUCCESS;
  }
  return BT::NodeStatus::RUNNING;
}

void MoveBaseAction::onHalted()
{
  printf("[ MoveBase: ABORTED ]");
}
```

## Sequence VS ReactiveSequence

以下示例应使用简单的`SequenceNode`。

``` xml hl_lines="3"
 <root BTCPP_format="4">
     <BehaviorTree>
        <Sequence>
            <BatteryOK/>
            <SaySomething   message="mission started..." />
            <MoveBase           goal="1;2;3"/>
            <SaySomething   message="mission completed!" />
        </Sequence>
     </BehaviorTree>
 </root>
```

``` cpp
int main()
{
  BT::BehaviorTreeFactory factory;
  factory.registerSimpleCondition("BatteryOK", std::bind(CheckBattery));
  factory.registerNodeType<MoveBaseAction>("MoveBase");
  factory.registerNodeType<SaySomething>("SaySomething");

  auto tree = factory.createTreeFromText(xml_text);
 
  // 这里，我们更喜欢使用自己的循环，
  // 而不是tree.tickWhileRunning()。
  std::cout << "--- ticking\n";
  auto status = tree.tickOnce();
  std::cout << "--- status: " << toStr(status) << "\n\n";

  while(status == NodeStatus::RUNNING) 
  {
    // 休眠以避免忙循环。
    // 不要使用其他休眠函数！
    // 小的休眠时间是可以的，这里我们使用较大的休眠时间只是为了
    // 在控制台上显示更少的消息。
    tree.sleep(std::chrono::milliseconds(100));

    std::cout << "--- ticking\n";
    status = tree.tickOnce();
    std::cout << "--- status: " << toStr(status) << "\n\n";
  }

  return 0;
}
```

预期输出：

``` 
--- ticking
[ Battery: OK ]
Robot says: mission started...
[ MoveBase: SEND REQUEST ]. goal: x=1.0 y=2.0 theta=3.0
--- status: RUNNING

--- ticking
--- status: RUNNING

--- ticking
[ MoveBase: FINISHED ]
Robot says: mission completed!
--- status: SUCCESS
```

你可能已经注意到，当调用`executeTick()`时，`MoveBase`在第1次和第2次返回__RUNNING__，最终在第3次返回__SUCCESS__。

`BatteryOK`只执行一次。

如果我们使用`ReactiveSequence`，当子节点`MoveBase`返回RUNNING时，序列会重新启动，条件`BatteryOK`会__再次__执行。

如果在任何时候，`BatteryOK`返回__FAILURE__，`MoveBase`动作将被_中断_（具体来说是_中止_）。

``` xml hl_lines="3"
 <root>
     <BehaviorTree>
        <ReactiveSequence>
            <BatteryOK/>
            <Sequence>
                <SaySomething   message="mission started..." />
                <MoveBase           goal="1;2;3"/>
                <SaySomething   message="mission completed!" />
            </Sequence>
        </ReactiveSequence>
     </BehaviorTree>
 </root>
```

预期输出：

``` 
--- ticking
[ Battery: OK ]
Robot says: mission started...
[ MoveBase: SEND REQUEST ]. goal: x=1.0 y=2.0 theta=3.0
--- status: RUNNING

--- ticking
[ Battery: OK ]
--- status: RUNNING

--- ticking
[ Battery: OK ]
[ MoveBase: FINISHED ]
Robot says: mission completed!
--- status: SUCCESS
```

## 事件驱动树？

:::tip
我们使用`tree.sleep()`命令而不是`std::this_thread::sleep_for()`是有原因的！！！
:::

应优先使用`Tree::sleep()`方法，因为当树中的节点"发生变化"时，它可以被中断。

当调用`TreeNode::emitStateChanged()`方法时，`Tree::sleep()`将被中断。