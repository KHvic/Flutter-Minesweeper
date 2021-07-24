import 'package:flutter/material.dart';
import './board.dart';

void main() => runApp(MineSweeper());

class MineSweeper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Mine Sweeper",
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Board(),
    );
  }
}
