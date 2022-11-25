import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';

class EnMaintenance extends StatelessWidget {
  const EnMaintenance({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(child: Center(child: Text("En maintenance"))));
  }
}
