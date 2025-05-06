## JavaScript in Flutter

[English](README.md) &nbsp;&nbsp;&nbsp; [中文](README.ZH.md)  

一个高性能、在Flutter中开箱即用的JavaScript引擎  


## 特性

1. 简单，开箱即用  
2. 最新的QuickJS支持  
3. 默认使用高性能编译策略  
4. 默认开启`big number`等特性  
5. 全平台支持，包括Web端  


## 快速开始

1. 在您的`pubspec.yaml`文件中添加`jsf`作为一个[依赖](https://pub.dev/packages/jsf/install)  
2. 直接像这样使用即可:  

```dart
class Example extends StatefulWidget {
  const Example({super.key});

  @override
  State<Example> createState() => _ExampleState();
}

class _ExampleState extends State<Example> {
  String _result = '';
  final _js = JsRuntime();

  void _runJS() {
    int result = _js.eval('44 + 55');
    setState(() {
      _result = result.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('JavaScript in Flutter')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _runJS,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 20,
                ),
                textStyle: const TextStyle(fontSize: 20),
              ),
              child: const Text('Run: 44 + 55'),
            ),
            const SizedBox(height: 20),
            Text('Get  $_result', style: const TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _js.dispose();
    super.dispose();
  }
}
```

执行`flutter run`，然后您将看到：  

![jsf_pic](https://moluopro.atomgit.net/web/jsf/pic.png)  


## 进阶内容

### 类型绑定

JSF为JavaScript中的常见数据类型提供了绑定：

```dart
  final _js = JsRuntime();

  var jsCode = [
    '44 + 55',
    '1.4 - 12',
    'true',
    'aaa',
    'new Date().toString()',
    '(123456789123456789123456789n * 2n)'
  ];

  for (int i = 0; i < jsCode.length; i++) {
    var result = _js.eval(jsCode[i]);
    print("$result: ${result.runtimeType}");
  }

  // 输出：
  // 99: int
  // -10.6: double
  // true: bool
  // null: Null
  // Tue May 06 2025 19:22:34 GMT+0800: String
  // 246913578246913578246913578: BigInt
```

在上面的示例中，`result`的类型取决于被执行的JavaScrip代码片段。

### Big Number

1. 在Native平台，`bigint`的类型是`_BigIntImpl`。
2. 在Web平台，`bigint`的类型是`JavaScriptBigInt`。
3. 这两种类型实现了相同的接口，因此在使用上几乎没有差别，无须在意。

### 调用JS库

这里我用[Ajv.js](https://ajv.js.org)作为例子(与`flutter_js`里一样的案例)：

```dart
  String ajvJS = await rootBundle.loadString("assets/ajv.js");
  String test = await rootBundle.loadString("assets/test.js");

  var ajvIsLoaded = _js.eval("!(typeof ajv == 'undefined')");

  // 判断Ajv.js是否已经导入
  if (!ajvIsLoaded) {
    _js.eval("var window = global = globalThis; $ajvJS");
  }

  var result = _js.eval(test);
  print(result);

  // 来自Ajv.js的输出结果：
  // data.id should be >= 0, data.email should match format "email", 
  // data should have required property 'worker'
```

可以看到，这里成功调用了`Ajv.js`里的函数。


## 相关项目

* [json_dynamic_widget](https://pub.dev/packages/json_dynamic_widget) 使用`JSF`作为脚本引擎进行热更新([官方插件](https://pub.dev/packages/json_dynamic_widget_plugin_js))  


## 常见问题

1. 为什么要创建这个包？  
我之前在使用`flutter_js`包，发现很多情况下无法顺利构建，并且它的`quickjs`版本非常旧。我看到有人反馈作者进行优化，但没有相关进展。此外，我在`pub.dev`上没有找到其他合适的替代品，遂决定自己写一个。  

2. 能够运行在哪些平台？  
我已经在Flutter支持的所有平台进行简单测试，目前暂未发现问题。  

3. 构建失败一般是因为什么？  
请检查您是否按照[官方文档](https://docs.flutter.dev/get-started/install)配置了Flutter开发环境。比如，Linux下应该[安装相关的包](https://docs.flutter.dev/get-started/install/linux/desktop#development-tools)，MacOS下要[安装xcode和cocoapad](https://docs.flutter.dev/get-started/install/macos/mobile-ios#development-tools)。  

4. 未来有什么更新规划？  
目前的功能已经足够我个人使用，所以不会增添新的东西。因此，如果您有其他的需求，欢迎提[issue](https://github.com/moluopro/jsf/issues)来告知我。  
