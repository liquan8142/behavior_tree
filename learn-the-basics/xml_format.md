# XML模式

在[第一个教程](tutorial-basics/tutorial_01_first_tree.md)中，展示了这个简单的树。

``` XML
 <root BTCPP_format="4">
     <BehaviorTree ID="MainTree">
        <Sequence name="root_sequence">
            <SaySomething   name="action_hello" message="Hello"/>
            <OpenGripper    name="open_gripper"/>
            <ApproachObject name="approach_object"/>
            <CloseGripper   name="close_gripper"/>
        </Sequence>
     </BehaviorTree>
 </root>
```

你可能注意到：

- 树的第一个标签是`<root>`。它应包含__1个或多个__标签`<BehaviorTree>`。

- 标签`<BehaviorTree>`应具有属性`[ID]`。

- 标签`<root>`应包含属性`[BTCPP_format]`。

- 每个TreeNode由单个标签表示。具体来说：

     - 标签的名称是用于在工厂中注册TreeNode的__ID__。
     - 属性`[name]`指的是实例的名称，是__可选的__。
     - 端口使用属性配置。在前面的示例中，动作`SaySomething`需要输入端口`message`。

- 在子节点数量方面：

     - `ControlNodes`包含__1到N个子节点__。
     - `DecoratorNodes`和子树包含__仅1个子节点__。
     - `ActionNodes`和`ConditionNodes`__没有子节点__。

## 端口重映射和指向黑板条目的指针

如[第二个教程](tutorial-basics/tutorial_02_basic_ports.md)中解释的，输入/输出端口可以使用黑板中条目的名称重映射，换句话说，BB的__键/值__对的__键__。

BB键使用此语法表示：`{key_name}`。

在以下示例中：

- Sequence的第一个子节点打印"Hello"，
- 第二个子节点读取和写入名为"my_message"的黑板条目中包含的值；

``` XML
 <root BTCPP_format="4" >
     <BehaviorTree ID="MainTree">
        <Sequence name="root_sequence">
            <SaySomething message="Hello"/>
            <SaySomething message="{my_message}"/>
        </Sequence>
     </BehaviorTree>
 </root>
```
     

## 紧凑 vs 显式表示

以下两种语法都有效：

``` XML
 <SaySomething               name="action_hello" message="Hello World"/>
 <Action ID="SaySomething"   name="action_hello" message="Hello World"/>
```

我们将前者称为"__紧凑__"语法，后者称为"__显式__"语法。第一个示例用显式语法表示将变为：

``` XML
 <root BTCPP_format="4" >
     <BehaviorTree ID="MainTree">
        <Sequence name="root_sequence">
           <Action ID="SaySomething"   name="action_hello" message="Hello"/>
           <Action ID="OpenGripper"    name="open_gripper"/>
           <Action ID="ApproachObject" name="approach_object"/>
           <Action ID="CloseGripper"   name="close_gripper"/>
        </Sequence>
     </BehaviorTree>
 </root>
```

即使紧凑语法更方便且更容易编写，但它提供的关于TreeNode模型的信息太少。像__Groot__这样的工具需要_显式_语法或附加信息。可以使用标签`<TreeNodeModel>`添加此信息。

要使树的紧凑版本与Groot兼容，必须如下修改XML：

``` XML
 <root BTCPP_format="4" >
     <BehaviorTree ID="MainTree">
        <Sequence name="root_sequence">
           <SaySomething   name="action_hello" message="Hello"/>
           <OpenGripper    name="open_gripper"/>
           <ApproachObject name="approach_object"/>
           <CloseGripper   name="close_gripper"/>
        </Sequence>
    </BehaviorTree>
	
	<!-- BT执行器不需要这个，但Groot需要 --> 	
    <TreeNodeModel>
        <Action ID="SaySomething">
            <input_port name="message" type="std::string" />
        </Action>
        <Action ID="OpenGripper"/>
        <Action ID="ApproachObject"/>
        <Action ID="CloseGripper"/>      
    </TreeNodeModel>
 </root>
```

## 子树

正如我们在[这个教程](tutorial-basics/tutorial_06_subtree_ports.md)中看到的，可以将子树包含在另一棵树中，以避免在多个位置"复制和粘贴"相同的树并减少复杂性。

假设我们想将一些动作封装到行为树"__GraspObject__"中（为简单起见，省略了可选的属性[name]）。

``` XML
 <root BTCPP_format="4" >
 
     <BehaviorTree ID="MainTree">
        <Sequence>
           <Action  ID="SaySomething"  message="Hello World"/>
           // highlight-next-line
           <SubTree ID="GraspObject"/>
        </Sequence>
     </BehaviorTree>
     
     <BehaviorTree ID="GraspObject">
        <Sequence>
           <Action ID="OpenGripper"/>
           <Action ID="ApproachObject"/>
           <Action ID="CloseGripper"/>
        </Sequence>
     </BehaviorTree>  
 </root>
```

我们可能注意到整个树"GraspObject"在"SaySomething"之后执行。

## 包含外部文件

__自版本2.4起__。

你可以包含外部文件，方式类似于C++中的'__#include \<file\>__'。我们可以使用标签轻松做到这一点：

``` XML
  <include path="relative_or_absolute_path_to_file">
``` 

使用前面的示例，我们可以将两个行为树拆分为两个文件：

``` XML hl_lines="5"
 <!-- 文件 maintree.xml -->

 <root BTCPP_format="4" >
	 
	 <include path="grasp.xml"/>
	 
     <BehaviorTree ID="MainTree">
        <Sequence>
           <Action  ID="SaySomething"  message="Hello World"/>
           <SubTree ID="GraspObject"/>
        </Sequence>
     </BehaviorTree>
  </root>
``` 

``` XML
 <!-- 文件 grasp.xml -->

 <root BTCPP_format="4" >
     <BehaviorTree ID="GraspObject">
        <Sequence>
           <Action ID="OpenGripper"/>
           <Action ID="ApproachObject"/>
           <Action ID="CloseGripper"/>
        </Sequence>
     </BehaviorTree>  
 </root>
```

:::note[ROS用户注意]
如果你想在[ROS包](http://wiki.ros.org/Packages)内找到文件，可以使用此语法：
:::

``` XML
<include ros_pkg="name_package"  path="path_relative_to_pkg/grasp.xml"/>
```