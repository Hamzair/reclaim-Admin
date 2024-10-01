import 'package:flutter/material.dart';
import 'package:simple_fontellico_progress_dialog/simple_fontico_loading.dart';
late SimpleFontelicoProgressDialog _dialog;
CreateInstanceLoadingProvider(context){
  _dialog = SimpleFontelicoProgressDialog(context: context);
}
showDialogLoading(String message,context,{int time=8})async{
  _dialog.show(message: message, backgroundColor:Color.fromRGBO(38, 70, 83, 1 ), indicatorColor: Colors.white, textStyle: TextStyle(color:Colors.white));
  if(time!=0){
    await Future.delayed(Duration(seconds: time),(){
      _dialog.hide();
    });}
}

dismissDialog(context){
  _dialog.hide();
}

showSnackbar(BuildContext context, String message) {
  final snackBar = SnackBar(
    content: Text(message,  style: TextStyle(color:Colors.white)),
    backgroundColor:Color.fromRGBO(38, 70, 83, 1 ),

  );

  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}