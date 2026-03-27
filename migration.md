---
title: 从BT.CPP 3.x迁移
description: 如何从版本3.8迁移你的代码
hide_table_of_contents: false
sidebar_position: 7
---

# 从版本3.8迁移到4.X

你会发现版本4.X中的大多数更改都是增量的，并且与你之前的代码向后兼容。

在这里，我们尝试总结迁移时你应该注意的最相关差异。

> [!NOTE]
> 在仓库中，你可以找到一个名为 **convert_v3_to_v4.py** 的Python脚本，可能为你节省一些时间（感谢用户https://github.com/SubaruArai）！
>
> 尝试使用它，但请确保首先仔细检查结果！

## 类重命名

以下类/XML标签的名称已更改。

| 3.8+中的名称 | 4.x中的名称 | 位置 |
|-------------|---------|---------|
| NodeConfiguration | NodeConfig | C++ |
| SequenceStar | SequenceWithMemory | C++和XML |
| AsyncActionNode | ThreadedAction | C++ |
| Optional | Expected | C++ |

如果你想快速修复C++代码的编译（ **即使鼓励重构** ），添加：

```cpp
namespace BT 
{
  using NodeConfiguration = NodeConfig;
  using AsyncActionNode = ThreadedAction;
  using Optional = Expected;
}
```

## XML

你应该向XML的\<root\>标签添加属性`BTCPP_format`：

之前：
```xml
<root>
```

现在：
```xml
<root BTCPP_format="4">
```

这将使我们最终能够与版本3和4兼容！

## SubTree和SubTreePlus

3.X中的默认 **SubTree** 已被弃用，转而使用 **SubtreePlus** 。由于这是新的默认值，我们简单地称它为"SubTree"。

| 3.8+中的名称 | 4.x中的名称 |
|-------------|---------|
| `<SubTree>` | 已弃用 |
| `<SubTreePlus>` | `<SubTree>` |

## SetBlackboard和BlackboardCheck

新的[脚本语言](/docs/guides/scripting)更简单、更强大。

另请查看[前置和后置条件](/docs/guides/pre_post_conditions)的介绍。

**3.8** 中的旧代码：

``` xml
<SetBlackboard output_key="port_A" value="42" />
<SetBlackboard output_key="port_B" value="69" />
<BlackboardCheckInt value_A="{port_A}" value_B="{port_B}" 
                    return_on_mismatch="FAILURE">
    <MyAction/>
</BlackboardCheckInt>
```

**4.X** 中的新代码：

``` xml
<Script code="port_A:=42; port_B:=69" />
<MyAction _failureIf="port_A!=port_B"/>
```

## 在While循环中触发

典型的执行过去看起来像这样：

```cpp
// 简化代码，在BT.CPP 3.8中常见
while(status != NodeStatus::SUCCESS || status == NodeStatus::FAILURE) 
{
  status tree.tickRoot();
  std::this_thread::sleep_for(sleep_ms);
}
```

行为树的"轮询"模型有时受到批评。休眠是必要的，以避免"忙循环"，但可能引入一些延迟。

为了提高行为树的响应性，我们引入了方法：
```cpp
Tree::sleep(std::chrono::milliseconds timeout)
```

这个特定的 **sleep** 实现可以在树中 **任何** 节点调用方法`TreeNode::emitWakeUpSignal`时被中断。这允许循环 **立即** 重新触发树。

方法`Tree::tickRoot()`已从公共API中移除，新的推荐方法是：

```cpp
// 使用Tree::sleep并等待SUCCESS或FAILURE
while(!BT::isStatusCompleted(status)) 
{
  status = tree.tickOnce();
  tree.sleep(sleep_ms);
}
//---- 或者，更好的是 ------
status = tree.tickWhileRunning(sleep_ms); 
```

`Tree::tickWhileRunning`是新的默认方法，它有自己的内部循环；第一个参数是循环内休眠的超时时间。

或者，你可以使用这些方法：

- `Tree::tickExactlyOnce()`：等同于3.8+中的旧行为
- `Tree::tickOnce()`大致等同于`tickWhileRunning(0ms)`。它可能触发多次。

# ControlNodes和Decorators必须支持NodeStatus:SKIPPED

这个新状态的目的是在[前置条件](/docs/guides/pre_post_conditions)不满足时返回。

当节点返回 **SKIPPED** 时，它通知其父节点（ControlNode或Decorator）它尚未执行。

> [!NOTE]
> 当你实现自己的自定义 **叶节点** 时，不应返回 **SKIPPED** 。此状态保留给前置条件。
>
> 另一方面， **ControlNodes和Decorators** 必须修改以支持这个新状态。


通常的经验法则是，如果子节点返回 **SKIPPED** ，意味着它未执行，ControlNode应移动到下一个。

# 异步控制节点

用户在这里发现了一个严重问题[here](https://github.com/BehaviorTree/BehaviorTree.CPP/issues/395)：

> 如果 **ControlNode** 或 **DecoratorNode** 只有同步子节点，则无法中断它们。

考虑这个示例：

```xml
<ReactiveSequence>
    <AbortCondition/>
    <Sequence name="synch_sequence">
        <SyncActionA/>
        <SyncActionB/>
        <SyncActionC/>
    <Sequence>
</ReactiveSequence>   
```
当`Sequence`（或`Fallback`）只有同步子节点时，整个序列变得"原子化"。

换句话说，当"synch_sequence"开始时，`AbortCondition`无法停止它。

为了解决这个问题，我们添加了两个新节点，`AsyncSequence`和`AsyncFallback`。

当使用`AsyncSequence`时，在执行 **每个** 同步子节点后返回 **RUNNING** ，然后再移动到下一个兄弟节点。

在上面的示例中，要成功完成整个树，我们需要3次触发。