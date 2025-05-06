## JavaScript in Flutter

[English](README.md) &nbsp;&nbsp;&nbsp; [中文](README.ZH.md)  

A high performance JavaScript engine, available out of the box in Flutter.  


## Features

1. Simple and ready to use out of the box  
2. Up-to-date support for the latest QuickJS  
3. High-performance compilation strategy enabled by default  
4. Advanced features such as `big number` support enabled by default  
5. Full platform support, including web  


## Getting Started

1. Add `jsf` as a [dependency](https://pub.dev/packages/jsf/install) in your `pubspec.yaml` file.  

2. Just use it:  

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

Run `flutter run`, then you will see:  

![jsf_pic](https://moluopro.atomgit.net/web/jsf/pic.png)  


## Advanced Topics

### Type Binding

`JSF` provides bindings for common data types in `JavaScript`:

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

  // Output: 
  // 99: int
  // -10.6: double
  // true: bool
  // null: Null
  // Tue May 06 2025 19:22:34 GMT+0800: String
  // 246913578246913578246913578: BigInt
```

In the example above, the type of `result` depends on the JavaScript code snippet being executed.

### Big Number

1. On the Native platform, the type of `bigint` is `_BigIntImpl`.
2. On the Web platform, the type of `bigint` is `JavaScriptBigInt`.
3. Both types implement the same interface, so there is virtually no difference in usage and no need to worry about the distinction.

### Calling JS Libraries

Here, I’ll use [Ajv.js](https://ajv.js.org) as an example (the same example used in `flutter_js`):

```dart
  String ajvJS = await rootBundle.loadString("assets/ajv.js");
  String test = await rootBundle.loadString("assets/test.js");

  var ajvIsLoaded = _js.eval("!(typeof ajv == 'undefined')");

  if (!ajvIsLoaded) {
    _js.eval("var window = global = globalThis; $ajvJS");
  }

  var result = _js.eval(test);
  print(result);

  // Output(from Ajv.js)：
  // data.id should be >= 0, data.email should match format "email", 
  // data should have required property 'worker'
```

As you can see, the function from `Ajv.js` was successfully called here.


## Related Project

* [json_dynamic_widget](https://pub.dev/packages/json_dynamic_widget) uses `JSF` as script for hot update (supported via [official plugin](https://pub.dev/packages/json_dynamic_widget_plugin_js))  


## FAQ

1. Why did you create this package?  
I was previously using the `flutter_js` package but often encountered build errors, and its `quickjs` version was very outdated. Although there were user reports suggesting that the author was working on improvements, no significant progress was observed. Additionally, I couldn't find any suitable alternatives on `pub.dev`, so I decided to develop one myself.  

2. Which platforms are supported?  
I have performed basic testing on all platforms supported by Flutter, and no issues have been identified so far.  

3. What are the common reasons for build failures?  
Please ensure your Flutter development environment is properly set up according to the [official documentation](https://docs.flutter.dev/get-started/install). For example, on Linux, make sure to [install the necessary packages](https://docs.flutter.dev/get-started/install/linux/desktop#development-tools), and on macOS, you need to [install Xcode and CocoaPods](https://docs.flutter.dev/get-started/install/macos/mobile-ios#development-tools).  

4. Are there any plans for future updates?  
The current functionality is sufficient for my personal use, so I do not plan to add new features. However, if you have other requirements, feel free to [submit an issue](https://github.com/moluopro/jsf/issues) to let me know.  
