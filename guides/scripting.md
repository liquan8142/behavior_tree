---
sidebar_position: 1
sidebar_label: 脚本语言
---

# 脚本介绍

行为树4.X引入了一个简单但强大的新概念：XML内的脚本语言。

实现的脚本语言具有熟悉的语法；它允许用户快速从黑板读取/写入变量。

学习脚本如何工作的最简单方法是使用内置动作 __Script__ ，它在[第二个教程](tutorial-basics/tutorial_02_basic_ports.md)中介绍过。

## 赋值运算符、字符串和数字

示例：

```
param_A := 42
param_B = 3.14
message = 'hello world'
```

- 第一行将数字42分配给黑板条目 __param_A__ 。
- 第二行将数字3.14分配给黑板条目 __param_B__ 。
- 第三行将字符串"hello world"分配给黑板条目 __message__ 。

> [!TIP]
> 运算符 __":="__ 和 __"="__ 的区别在于，前者如果条目不存在，可能在黑板中创建新条目，而后者如果黑板不包含该条目，将抛出异常。

你还可以使用 __分号__ 在单个脚本中添加多个命令。

```
A:= 42; B:=24
```

### 算术运算符和括号

示例：

```
param_A := 7
param_B := 5
param_B *= 2
param_C := (param_A * 3) + param_B
```

`param_B`的结果值是10，`param_C`是31。

支持以下运算符：

| 运算符 | 赋值运算符  | 描述 |
|----------|---------|---------|
| +        |  +=     | 加      |
| -        |  -=     | 减 |
| *        |  *=     | 乘 |
| /        |  /=     | 除   |

注意加法运算符是唯一也适用于字符串的运算符（用于连接两个字符串）。

## 位运算符和十六进制数字

这些运算符仅在值可以转换为整数时有效。

将它们与字符串或实数一起使用将导致异常。

示例：

```
value:= 0x7F
val_A:= value & 0x0F
val_B:= value | 0xF0
```

`val_A`的值是0x0F（或15）；`val_B`是0xFF（或255）。

| 二元运算符 | 描述 |
|----------|---------|
| \|       |  按位或   |
| &        |  按位与 |
| ^        |  按位异或 |

| 一元运算符 | 描述 |
|----------|---------|
| ~        |  取反   |

## 逻辑和比较运算符

返回布尔值的运算符。

示例：

```
val_A := true
val_B := 5 > 3
val_C := (val_A == val_B)
val_D := (val_A && val_B) || !val_C
```

| 运算符 | 描述 |
|----------|---------|
| true/false |  布尔值。可分别转换为1和0   |
| `&&`       |  逻辑与 |
| `\|\|`     |  逻辑或 |
| `!`        |  取反 |
| `==`       |  相等 |
| `!=`       |  不等 |
| `<`        |  小于 |
| `<=`       |  小于等于 |
| `>`        |  大于 |
| `>=`       |  大于等于 |

### 三元运算符 **if-then-else**

示例：

```
val_B = (val_A > 1) ? 42 : 24
```

## 布尔值
布尔值可以是`true`或`false`之一，并分别保存到黑板为`1`和`0`。

设置布尔值：
```
val_A = true
val_B := !false
```
逻辑`!`适用于布尔字面量。`!false`等同于`true`。上面的`val_A`和`val_B`是等价的。

使用布尔值：
```
<Precondition if="val_A" else="FAILURE">
<Precondition if="val_A == true" else="FAILURE">
<Precondition if="val_A == 1" else="FAILURE">
```
上面在前提条件节点中使用的所有脚本都是有效的。

评估布尔值时，可以：
 - 直接检查，
 - 与字面量`true`和`false`比较
 - 与`1`和`0`比较。

注意，以任何方式大写单词"true"和"false"都不起作用。

## C++示例

演示脚本语言，包括如何使用枚举表示 **整数值** 。

XML：

``` xml
<root >
    <BehaviorTree>
        <Sequence>
            <Script code=" msg:='hello world' " />
            <Script code=" A:=THE_ANSWER; B:=3.14; color:=RED " />
            <Precondition if="A>B && color!=BLUE" else="FAILURE">
                <Sequence>
                  <SaySomething message="{A}"/>
                  <SaySomething message="{B}"/>
                  <SaySomething message="{msg}"/>
                  <SaySomething message="{color}"/>
                </Sequence>
            </Precondition>
        </Sequence>
    </BehaviorTree>
</root>
```

注册节点和枚举的C++代码：

``` cpp
int main()
{
  // 简单的树：两个异步动作的序列，
  // 但由于超时，第二个将被中止。

  BehaviorTreeFactory factory;
  factory.registerNodeType<SaySomething>("SaySomething");

  enum Color { RED=1, BLUE=2, GREEN=3 };
  // 我们可以将这些枚举添加到脚本语言中
  factory.registerScriptingEnums<Color>();

  // 或者我们可以手动完成
  factory.registerScriptingEnum("THE_ANSWER", 42);

  auto tree = factory.createTreeFromText(xml_text);
  tree.tickWhileRunning();
  return 0;
}
```

预期输出：

```
Robot says: 42.000000
Robot says: 3.140000
Robot says: hello world
Robot says: 1.000000
```

注意，在底层，枚举总是被解释为其数值。