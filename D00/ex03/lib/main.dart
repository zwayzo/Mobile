import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:math_expressions/math_expressions.dart';

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
  String displayText = "";

  void calculate() {
    setState(() {
      
      int result = number1 + number2;
    });
  }


Widget buildButton(String text) {
  return Expanded(
    child: GestureDetector(
      onTap: () {
        setState(() {
          String lastChar = displayText.isNotEmpty ? displayText[displayText.length - 1] : '';
            if (displayText.isEmpty && (text == '+' || text == '*' || text == '/')) {
              return; 
            }
            if (displayText != '+' && displayText != '-' && displayText != '*' && displayText != '/')
              displayText += text;
            if (displayText == "Error" || displayText == "Infinity") {
              displayText = "";
            }
            if (text == 'C' && displayText.isNotEmpty) {
              displayText = displayText.substring(0, displayText.length - 1);
            } else if (text == 'AC') {
              displayText = "";
            } else if (text == '=') {
              try {
                Parser p = Parser();
                Expression exp = p.parse(displayText); //expression tree
                ContextModel cm = ContextModel();
                double result = exp.evaluate(EvaluationType.REAL, cm);
                displayText = result.toString();
              } catch (e) {
                displayText = "Error";
              }


            }
            else if ((displayText.isNotEmpty) && (text == '+' || text == '-' || text == '*' || text == '/')  && (displayText[displayText.length -1] == '+' || displayText[displayText.length -1] == '-' || displayText[displayText.length -1] == '*' || displayText[displayText.length -1] == '/')) {
              displayText = displayText.substring(0, displayText.length - 1) + text;
    
            }
             else if (text == '.') {
              int lastOperatorIndex = displayText.lastIndexOf(RegExp(r'[+\-*/]'));
              String currentNumber = displayText.substring(lastOperatorIndex + 1);
              if (!currentNumber.contains('.')) {
                displayText += '.';
              }
             }
        });
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
          
          
          children: [
            Expanded(
            child: Container(
              alignment: Alignment.bottomRight,
              padding: EdgeInsets.all(16),
              child: Text(
                displayText.isEmpty ? "0" : '$displayText',
                style: TextStyle(fontSize: 40),
              ),
            ),
          ),
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
                buildButton(''),
                buildButton(''),
                buildButton('='),
              ]
            )
          ],
        ),
      ),
    ),
  );
}
}