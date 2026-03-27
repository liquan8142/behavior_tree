---
sidebar_position: 10
sidebar_label: 10. 日志记录器与观察者
---

# 日志记录器接口

BT.CPP提供了一种在运行时向树添加**日志记录器**的方式，通常是在树创建之后、开始触发它之前。

"日志记录器"是一个类，每当TreeNode改变其状态时都会调用其回调；这是所谓的[观察者模式](https://en.wikipedia.org/wiki/Observer_pattern)的非侵入式实现。

更具体地说，将被调用的回调是：

```cpp
  virtual void callback(
    BT::Duration timestamp, // 转换发生的时间
    const TreeNode& node,   // 改变状态的节点
    NodeStatus prev_status, // 先前的状态
    NodeStatus status);     // 新的状态
```

## TreeObserver类

有时，特别是在实现**单元测试**时，了解某个节点返回SUCCESS或FAILURE的次数是很方便的。

例如，我们想要检查在特定条件下，是否执行了某个分支而另一个分支没有执行。

`TreeObserver`是一个简单的日志记录器实现，它为树的每个节点收集以下统计信息：

```cpp
struct NodeStatistics
  {
    // 最后有效的结果，SUCCESS或FAILURE
    NodeStatus last_result;
    // 最后状态。可以是任何状态，包括IDLE或SKIPPED
    NodeStatus current_status;
    // 状态转换计数，不包括转换到IDLE
    unsigned transitions_count;
    // 转换到SUCCESS的次数
    unsigned success_count;
    // 转换到FAILURE的次数
    unsigned failure_count;
    // 转换到SKIPPED的次数
    unsigned skip_count;
    // 最后一次转换的时间戳
    Duration last_timestamp;
  };
```

## 如何唯一标识一个节点

由于观察者允许我们收集特定节点的统计信息，我们需要一种方式来唯一标识该节点：

可以使用两种机制：

- `TreeNode::UID()`，这是一个唯一的数字，对应于树的[深度优先遍历](https://en.wikipedia.org/wiki/Depth-first_search)。

- `TreeNode::fullPath()`，旨在成为特定节点的唯一但人类可读的标识符。

我们使用术语"路径"，因为典型的字符串值可能看起来像这样：

     first_subtree/nested_subtree/node_name

换句话说，路径包含有关节点在子树层次结构中的位置信息。

"node_name"要么是在XML中分配的名称属性，要么是自动分配的，使用节点注册名后跟"::"和UID。

## 示例（XML）

考虑以下XML，它在子树方面具有非平凡的层次结构：

```xml
<root BTCPP_format="4">
  <BehaviorTree ID="MainTree">
    <Sequence>
     <Fallback>
       <AlwaysFailure name="failing_action"/>
       <SubTree ID="SubTreeA" name="mysub"/>
     </Fallback>
     <AlwaysSuccess name="last_action"/>
    </Sequence>
  </BehaviorTree>

  <BehaviorTree ID="SubTreeA">
    <Sequence>
      <AlwaysSuccess name="action_subA"/>
      <SubTree ID="SubTreeB" name="sub_nested"/>
      <SubTree ID="SubTreeB" />
    </Sequence>
  </BehaviorTree>

  <BehaviorTree ID="SubTreeB">
    <AlwaysSuccess name="action_subB"/>
  </BehaviorTree>
</root>
```

你可能注意到一些节点具有XML属性"name"，而其他节点没有。

对应的**UID** -> **fullPath**对列表是：

```
1 -> Sequence::1
2 -> Fallback::2
3 -> failing_action
4 -> mysub
5 -> mysub/Sequence::5
6 -> mysub/action_subA
7 -> mysub/sub_nested
8 -> mysub/sub_nested/action_subB
9 -> mysub/SubTreeB::9
10 -> mysub/SubTreeB::9/action_subB
11 -> last_action
```

## 示例（C++）

以下应用程序将：

- 递归打印树的结构。
- 将`TreeObserver`附加到树。
- 打印`UID / fullPath`对。
- 收集名为"last_action"的特定节点的统计信息。
- 显示观察者收集的所有统计信息。

```cpp
int main()
{
  BT::BehaviorTreeFactory factory;

  factory.registerBehaviorTreeFromText(xml_text);
  auto tree = factory.createTree("MainTree");

  // 辅助函数，用于打印树。
  BT::printTreeRecursively(tree.rootNode());

  // 观察者的目的是保存关于某个节点返回SUCCESS或FAILURE次数的统计信息。
  // 这对于创建单元测试和检查是否按预期发生某些转换特别有用
  BT::TreeObserver observer(tree);

  // 打印唯一ID和对应的人类可读路径
  // 路径也应该是唯一的。
  std::map<uint16_t, std::string> ordered_UID_to_path;
  for(const auto& [name, uid]: observer.pathToUID()) {
    ordered_UID_to_path[uid] = name;
  }

  for(const auto& [uid, name]: ordered_UID_to_path) {
    std::cout << uid << " -> " << name << std::endl;
  }


  tree.tickWhileRunning();

  // 你可以使用完整路径或UID访问特定的统计信息
  const auto& last_action_stats = observer.getStatistics("last_action");
  assert(last_action_stats.transitions_count > 0);

  std::cout << "----------------" << std::endl;
  // 打印所有统计信息
  for(const auto& [uid, name]: ordered_UID_to_path) {
    const auto& stats = observer.getStatistics(uid);

    std::cout << "[" << name
              << "] \tT/S/F:  " << stats.transitions_count
              << "/" << stats.success_count
              << "/" << stats.failure_count
              << std::endl;
  }

  return 0;
}
```