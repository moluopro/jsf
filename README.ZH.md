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

JSF为JavaScript中的常见数据类型提供了绑定，比如int, bigint, double, bool, string, and null.


## 相关项目

* [json_dynamic_widget](https://pub.dev/packages/json_dynamic_widget) 使用`JSF`作为脚本引擎进行热更新([官方插件](https://pub.dev/packages/json_dynamic_widget_plugin_js/versions/2.2.0+1#introduction))  


## 常见问题

1. 为什么要创建这个包？  
我之前在使用`flutter_js`包，发现很多情况下无法顺利构建，并且它的`quickjs`版本非常旧。我看到有人反馈作者进行优化，但没有相关进展。此外，我在`pub.dev`上没有找到其他合适的替代品，遂决定自己写一个。  

2. 能够运行在哪些平台？  
我已经在Flutter支持的所有平台进行简单测试，目前暂未发现问题。  

3. 构建失败一般是因为什么？  
请检查您是否按照[官方文档](https://docs.flutter.dev/get-started/install)配置了Flutter开发环境。比如，Linux下应该[安装相关的包](https://docs.flutter.dev/get-started/install/linux/desktop#development-tools)，MacOS下要[安装xcode和cocoapad](https://docs.flutter.dev/get-started/install/macos/mobile-ios#development-tools)。  

4. 未来有什么更新规划？  
目前的功能已经足够我个人使用，所以不会增添新的东西。因此，如果您有其他的需求，欢迎提[issue](https://github.com/moluopro/jsf/issues)来告知我。  
