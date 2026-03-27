# 装饰器

装饰器是必须有一个子节点的节点。

由装饰器决定是否、何时以及多少次触发子节点。

> 有关内置节点的完整列表，请参见本节的其他页面和Github上的[源代码](https://github.com/BehaviorTree/BehaviorTree.CPP/tree/master/include/behaviortree_cpp)。

## Inverter

触发子节点一次，如果子节点失败则返回SUCCESS，如果子节点成功则返回FAILURE。

如果子节点返回RUNNING，此节点也返回RUNNING。

## ForceSuccess

如果子节点返回RUNNING，此节点也返回RUNNING。

否则，它总是返回SUCCESS。

## ForceFailure

如果子节点返回RUNNING，此节点也返回RUNNING。

否则，它总是返回FAILURE。

## Repeat

只要子节点返回SUCCESS，就触发子节点最多N次。

| 端口 | 类型 | 默认值 | 描述 |
|------|------|---------|-------------|
| `num_cycles` | InputPort\<int\> | (必需) | 重复次数。使用`-1`表示无限循环。 |

- 所有N次重复成功完成后返回 **SUCCESS** 。
- 如果子节点返回FAILURE，立即返回 **FAILURE** （循环中断）。
- 如果子节点返回RUNNING，返回 **RUNNING** ；计数器 **不** 递增，相同的迭代在下次触发时恢复。
- 如果子节点返回 **SKIPPED** ，子节点被重置但计数器不递增。

```xml
<Repeat num_cycles="3">
    <ClapYourHandsOnce/>
</Repeat>
```

## RetryUntilSuccessful

只要子节点返回FAILURE，就触发子节点最多N次。

| 端口 | 类型 | 默认值 | 描述 |
|------|------|---------|-------------|
| `num_attempts` | InputPort\<int\> | (必需) | 尝试次数。使用`-1`表示无限重试。 |

- 如果子节点返回SUCCESS，立即返回 **SUCCESS** （循环中断）。
- 所有N次尝试用尽后返回 **FAILURE** 。
- 如果子节点返回RUNNING，返回 **RUNNING** ；尝试计数器 **不** 递增，相同的迭代在下次触发时恢复。
- 如果子节点返回 **SKIPPED** ，子节点被重置并返回SKIPPED。

```xml
<RetryUntilSuccessful num_attempts="3">
    <OpenDoor/>
</RetryUntilSuccessful>
```

:::note
已弃用的名称`RetryUntilSuccesful`（单个's'）仍向后兼容支持，但不应在新树中使用。
:::

## KeepRunningUntilFailure

KeepRunningUntilFailure节点总是返回FAILURE（子节点中的FAILURE）或RUNNING（子节点中的SUCCESS或RUNNING）。

## Delay

在指定时间过去后触发子节点。延迟通过[输入端口](tutorial-basics/tutorial_02_basic_ports.md) `delay_msec`指定。如果子节点返回RUNNING，此节点也返回RUNNING，并将在Delay节点的下次触发时触发子节点。否则，返回子节点的状态。

## Timeout

如果子节点运行时间超过给定持续时间，则中止正在运行的子节点。这与Delay相反：Delay在触发子节点*之前*等待，而Timeout中断*耗时过长*的子节点。

| 端口 | 类型 | 默认值 | 描述 |
|------|------|---------|-------------|
| `msec` | InputPort\<unsigned\> | (必需) | 超时持续时间（毫秒）。 |

- 如果子节点在超时前完成（SUCCESS或FAILURE），则返回其状态。
- 如果超时到期时子节点仍在RUNNING，则它被中止并返回 **FAILURE** 。

```xml
<Timeout msec="5000">
    <KeepYourBreath/>
</Timeout>
```

:::tip
将Timeout与RetryUntilSuccessful结合使用，实现健壮的超时重试模式：

```xml
<RetryUntilSuccessful num_attempts="3">
    <Timeout msec="5000">
        <LongRunningAction/>
    </Timeout>
</RetryUntilSuccessful>
```
:::

## RunOnce

RunOnce节点用于只想执行子节点一次的情况。如果子节点是异步的，它将触发直到返回SUCCESS或FAILURE。

在第一次执行后，你可以设置[输入端口](tutorial-basics/tutorial_02_basic_ports.md) `then_skip`的值：

- TRUE（默认），节点将来将被跳过。
- FALSE，永远同步返回子节点返回的相同状态。

## Precondition

Precondition装饰器在触发其子节点之前评估脚本条件。

| 端口 | 类型 | 默认值 | 描述 |
|------|------|---------|-------------|
| `if` | InputPort\<std::string\> | (必需) | 要评估的脚本条件 |
| `else` | InputPort\<NodeStatus\> | FAILURE | 条件为false时返回的状态 |

- 如果条件为 **true** ，触发子节点。
- 如果条件为 **false** ，节点返回`else`中指定的状态。
- 一旦子节点开始（返回RUNNING），条件 **不会重新评估** ，直到子节点完成。

```xml
<Precondition if="battery_level > 20" else="FAILURE">
    <MoveToGoal/>
</Precondition>
```

:::tip 每次触发评估
如果你需要在子节点运行时每次触发都检查条件（例如，当条件改变时中断正在运行的动作），使用`else="RUNNING"`：

```xml
<Precondition if="battery_ok" else="RUNNING">
    <LongRunningAction/>
</Precondition>
```

使用`else="RUNNING"`，如果条件变为false，装饰器返回RUNNING而不是FAILURE，允许树继续触发并重新检查条件。
:::

更多详细信息，请参见[前置和后置条件](../guides/pre_post_conditions.md)和[脚本语言介绍](../tutorial-basics/tutorial_09_scripting.md#script和precondition节点)。

## SubTree

参见[使用子树组合行为](../tutorial-basics/tutorial_05_subtrees)。

## 其他需要在C++中注册的装饰器

空队列将返回SUCCESS

例如，使用`factory.registerNodeType<ConsumeQueue<Pose2D>>("ConsumeQueue");`注册。参见[t18_waypoints.cpp](https://github.com/BehaviorTree/BehaviorTree.CPP/blob/master/examples/t18_waypoints.cpp)。

### SimpleDecoratorNode

使用`void BehaviorTreeFactory::registerSimpleDecorator("MyDecorator", tick_function, ports)`注册简单装饰器节点，它在内部使用`SimpleDecoratorNode`，其中`tick_function`是签名为`std::function<NodeStatus(NodeStatus, TreeNode&)>`的函数，ports是`PortsList`类型的变量。