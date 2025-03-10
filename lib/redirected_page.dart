import 'package:flutter/material.dart';

class RedirectedPage extends StatelessWidget {
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        margin: EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text('You are welcome!', style: TextStyle(fontSize: 30),),
          ],
        ),
      )
    );
  }
}