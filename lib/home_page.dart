import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class HomePage extends StatelessWidget {

  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Batata!',
          style: TextStyle(
            color: Colors.red,
            fontSize: 30,
          ),
        ),
        actions: const [
          Center(child: Text('XXXXX'),),
          Center(child: Text('YYYYY'),)
        ],
      ),
      drawer: const Drawer(),
      body: Container(
        width: 400,
        height: 400,
        color: Colors.green,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Center(
              child: Text('Teste'),),
            Text('Teste'),
            SizedBox(height: 50,),
            Text('Teste'),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
              Text('Teste Row'),
              SizedBox(width: 100,),
              Text('Teste Row'),
            ],)
          ],
        ),
      ),
    );
  }

}