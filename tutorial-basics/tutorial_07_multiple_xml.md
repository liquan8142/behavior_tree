---
sidebar_position: 7
sidebar_label: 07. 使用多个XML文件
---

# 如何使用多个XML文件

在我们展示的示例中，我们总是从 **单个XML文件** 创建整个树及其子树。

但是随着子树数量的增长，使用多个文件会更加方便。

## 我们的子树

文件 **subtree_A.xml** ：

``` xml
<root>
    <BehaviorTree ID="SubTreeA">
        <SaySomething message="Executing Sub_A" />
    </BehaviorTree>
</root>
```

文件 **subtree_B.xml** ：

``` xml 
<root>
    <BehaviorTree ID="SubTreeB">
        <SaySomething message="Executing Sub_B" />
    </BehaviorTree>
</root>
```

## 手动加载多个文件（推荐）

让我们考虑一个应该包含其他2个文件的 **main_tree.xml** ：

``` xml 
<root>
    <BehaviorTree ID="MainTree">
        <Sequence>
            <SaySomething message="starting MainTree" />
            // highlight-start
            <SubTree ID="SubTreeA" />
            <SubTree ID="SubTreeB" />
            // highlight-end
        </Sequence>
    </BehaviorTree>
</root>
```

要手动加载多个文件：

``` cpp
int main()
{
  BT::BehaviorTreeFactory factory;
  factory.registerNodeType<DummyNodes::SaySomething>("SaySomething");

  // 在文件夹中找到所有XML文件并注册它们。
  // 我们将使用std::filesystem::directory_iterator
  std::string search_directory = "./";

  using std::filesystem::directory_iterator;
  for (auto const& entry : directory_iterator(search_directory)) 
  {
    if( entry.path().extension() == ".xml")
    {
      factory.registerBehaviorTreeFromFile(entry.path().string());
    }
  }
  // 这，在我们的特定情况下，将等同于
  // factory.registerBehaviorTreeFromFile("./main_tree.xml");
  // factory.registerBehaviorTreeFromFile("./subtree_A.xml");
  // factory.registerBehaviorTreeFromFile("./subtree_B.xml");

  // 你可以创建MainTree，子树将自动添加。
  std::cout << "----- MainTree tick ----" << std::endl;
  auto main_tree = factory.createTree("MainTree");
  main_tree.tickWhileRunning();

  // ... 或者你可以只创建其中一个子树
  std::cout << "----- SubA tick ----" << std::endl;
  auto subA_tree = factory.createTree("SubTreeA");
  subA_tree.tickWhileRunning();

  return 0;
}
/* 预期输出：

Registered BehaviorTrees:
 - MainTree
 - SubTreeA
 - SubTreeB
----- MainTree tick ----
Robot says: starting MainTree
Robot says: Executing Sub_A
Robot says: Executing Sub_B
----- SubA tick ----
Robot says: Executing Sub_A
```

## 使用"include"添加多个文件

如果你更喜欢将包含树的信息移动到XML本身，你可以如下修改 **main_tree.xml** ：

``` xml
<root BTCPP_format="4">
    // highlight-start
    <include path="./subtree_A.xml" />
    <include path="./subtree_B.xml" />
    <BehaviorTree ID="MainTree">
    // highlight-end
        <Sequence>
            <SaySomething message="starting MainTree" />
            <SubTree ID="SubTreeA" />
            <SubTree ID="SubTreeB" />
        </Sequence>
    </BehaviorTree>
</root>
```

正如你可能注意到的，我们在 **main_tree.xml** 中包含了两个相对路径，告诉`BehaviorTreeFactory`在哪里找到所需的依赖项。

路径是相对于 **main_tree.xml** 的。

我们现在可以像往常一样创建树：

``` cpp
factory.createTreeFromFile("main_tree.xml")
```