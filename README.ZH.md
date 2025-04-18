## JavaScript in Flutter

[English](README.md) &nbsp;&nbsp;&nbsp; [中文](README.ZH.md)  

一个高性能、在Flutter中开箱即用的JavaScript引擎  

### 特性

1. 简单，开箱即用  
2. 最新的QuickJS支持  
3. 默认使用高性能编译策略  
4. 默认开启`big number`等特性  
5. Web平台支持(通过`dart:js_interop`)  

### 快速开始

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
    final result = _js.eval('44 + 55');
    setState(() {
      _result = result;
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
