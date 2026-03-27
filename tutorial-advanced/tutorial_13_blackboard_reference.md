---
sidebar_position: 13
sidebar_label: 13. 通过引用访问端口
---

# 零拷贝访问黑板

如果你遵循了教程，你应该已经知道黑板使用**值语义**，即方法`getInput`和`setOutput`从/向黑板复制值。

在某些情况下，可能希望使用**引用语义**，即直接访问存储在黑板中的对象。这在对象是以下情况时特别重要：

- 复杂的数据结构
- 复制成本高
- 不可复制。

例如，推荐使用引用语义的节点是`LoopNode`装饰器，它"原地"修改对象向量。

## 方法1：黑板条目作为共享指针

为简单起见，我们将考虑一个复制成本高的对象，称为**Pointcloud**。

假设我们有一个简单的BT，如下所示：

 ```xml 
  <root BTCPP_format="4" >
     <BehaviorTree ID="SegmentCup">
        <Sequence>
            <AcquirePointCloud  cloud="{pointcloud}"/>
            <SegmentObject  obj_name="cup" cloud="{pointcloud}" obj_pose="{pose}"/>
        </Sequence>
     </BehaviorTree>
 </root>
 ```

 - **AcquirePointCloud**将写入黑板条目`pointcloud`。
 - **SegmentObject**将从该条目读取。

 在这种情况下，推荐的端口类型是：

```cpp
PortsList AcquirePointCloud::providedPorts()
{
    return { OutputPort<std::shared_ptr<Pointcloud>>("cloud") };
}

PortsList SegmentObject::providedPorts()
{
    return { InputPort<std::string>("obj_name"),
             InputPort<std::shared_ptr<Pointcloud>>("cloud"),
             OutputPort<Pose3D>("obj_pose") };
}
```

方法`getInput`和`setOutput`可以像往常一样使用，并且仍然具有值语义。但由于被复制的对象是`shared_ptr`，我们实际上是通过引用访问点云实例。

## 方法2：线程安全的castPtr（自版本4.5.1起推荐）

使用`shared_ptr`方法时最显著的问题是它**不是线程安全的**。

如果自定义异步节点有自己的线程，那么实际对象可能同时被其他线程访问。

为了防止这个问题，我们提供了一个包含锁定机制的不同API。

首先，在创建我们的端口时，我们可以使用普通的`Pointcloud`，不需要将其包装在`std::shared_ptr`中：

```cpp
PortsList AcquirePointCloud::providedPorts()
{
    return { OutputPort<Pointcloud>("cloud") };
}

PortsList SegmentObject::providedPorts()
{
    return { InputPort<std::string>("obj_name"),
             InputPort<Pointcloud>("cloud"),
             OutputPort<Pose3D>("obj_pose") };
}
```

要通过指针/引用访问Pointcloud实例：

```cpp
// 在下面的作用域内，只要"any_locked"存在，保护"cloud"实例的互斥锁将保持锁定
if(auto any_locked = getLockedPortContent("cloud"))
{
  if(any_locked->empty())
  {
    // 黑板中的条目尚未初始化。
    // 你可以通过以下方式初始化它：
    any_locked.assign(my_initial_pointcloud);
  }
  else if(Pointcloud* cloud_ptr = any_locked->castPtr<Pointcloud>())
  {
    // 成功转换为Pointcloud*（原始类型）。
    // 使用cloud_ptr修改点云实例
  }
}
```