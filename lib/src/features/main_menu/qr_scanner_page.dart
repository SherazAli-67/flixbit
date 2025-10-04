import 'package:flutter/material.dart';

class QRScannerView extends StatelessWidget{
  const QRScannerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: Center(child: Text("QR Scanner Page"),)),
    );
  }

}