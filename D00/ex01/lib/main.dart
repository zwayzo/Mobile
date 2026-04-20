import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';

void main() {
  runApp(
    DevicePreview(
      enabled: true,
      builder: (context) {
        return MaterialApp(
          useInheritedMediaQuery: true,
          locale: DevicePreview.locale(context),
          builder: DevicePreview.appBuilder,
          home: TextChange(),
        );
      },
    ),
  );
}

class TextChange extends StatefulWidget {
  @override
  _TextChangeState createState() => _TextChangeState();
}

class _TextChangeState extends State<TextChange> {
  String _text1 = "Hello World";
  String _text2 = "Flutter is awesome";

  void changeText() {
    setState(() {
      print("Button pressed");
      if (_text1 == "Hello World") {
        _text1 = "Flutter is awesome";
        _text2 = "Hello World";
      } else {
        _text1 = "Hello World";
        _text2 = "Flutter is awesome";
      }
    }
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ex01'),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: size.width * 0.05),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(size.width * 0.05),
                  color: Colors.blue,
                  child: Text(
                    '$_text2',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: size.width * 0.06,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: size.height * 0.03),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: changeText,
                    child: Padding(
                      padding:  EdgeInsets.symmetric(
                        vertical: size.height * 0.02,
                      ),
                      child: Text(
                        "Press me",
                        style: TextStyle(
                          fontSize: size.width * 0.05,
                        ),
                      ),
                    ),
                  ),

                )
              ],
            ),
          ),
        ),
      )
    );
  }
}