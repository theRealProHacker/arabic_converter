import 'dart:math';
import 'package:flutter/material.dart';

/// A general ParseError
class ParseError implements Exception {
  late String message;
  ParseError(this.message);
}

/// Flips anything
Widget flip(Widget elem) {
  return Transform(
    transform: Matrix4.rotationY(pi),
    alignment: Alignment.center,
    child: elem,
  );
}

/// Full toolbar for input elements
const fullToolbar = ToolbarOptions(
  copy: true,
  cut: true,
  paste:true,
  selectAll: true,
);

/// InputDecoration with OutLineBorder
const boxInput = InputDecoration(border: OutlineInputBorder());

/// Alert a message to the user
alert(String message, BuildContext context){
  showDialog(context: context, builder: (context) {
    return AlertDialog(title: const Text("Hello, World!"), content: Text(message));
  });
}

smallAlert(String message, BuildContext context) {
  final snackBar = SnackBar(content: Text(message));
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}

/// Flip a mappin
Map<String,String> flipMap(Map<String,String> map){
  return {
    for (var pair in map.entries) 
      pair.value : pair.key
  };
}

enum Lang {
  arab,
  latin  
}

/// directions lookup by lang
const directions = <Lang, TextDirection>{
  Lang.arab :TextDirection.rtl,
  Lang.latin:TextDirection.ltr,
};
