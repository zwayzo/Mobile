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
          home: Calculator(),
        );
      },
    ),
  );
}

class Calculator extends StatefulWidget {
  @override
  _CalculatorState createState() => _CalculatorState();
}

class _CalculatorState extends State<Calculator> {
  int number1 = 0;
  int number2 = 0;

  void calculate() {
    setState(() {
      int result = number1 + number2;
    });
  }


Widget buildButton(String text) {
  return Expanded(
    child: GestureDetector(
      onTap: () {
        print('Button $text tapped');
      },
      child: Container(
        margin: EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(fontSize: 20, color: Colors.white),
        ),
      ),
    ),
  );
}



@override
Widget build(BuildContext context) {
  final size = MediaQuery.of(context).size;
  return Scaffold(
    appBar: AppBar(
      title: const Text('Calculator'),
      backgroundColor: Colors.grey,

    ),
    body: SafeArea(
      child: Center(
        child: Column(
          
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buildButton('7'),
                buildButton('8'),
                buildButton('9'),
                buildButton('C'),
                buildButton('AC'),
                
              ]
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buildButton('4'),
                buildButton('5'),
                buildButton('6'),
                buildButton('+'),
                buildButton('-'),
              ]
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buildButton('1'),
                buildButton('2'),
                buildButton('3'),
                buildButton('*'),
                buildButton('/'),
              ]
            ),            
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buildButton('0'),
                buildButton('.'),
                buildButton('00'),
                buildButton('='),
                buildButton(''),
              ]
            )
          ],
        ),
      ),
    ),
  );
}
}