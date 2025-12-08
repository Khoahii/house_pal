import 'package:flutter/material.dart';

class FundScreen extends StatelessWidget {
  const FundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:  AppBar(
        title: const Text("page funds"),
        // backgroundColor: Colors.transparent,
        // elevation: 0,
        // leading: IconButton(
        //   icon: const Icon(Icons.arrow_back_ios, color: Color.fromARGB(255, 11, 11, 11)),
        //   onPressed: () => Navigator.pop(context),
        // ),
      ),
      body: Center(child: Text("page funds")),
    );
  }
}
