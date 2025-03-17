import 'dart:async';

import 'package:android_serial_port/android_serial_port.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {}

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Column(
          children: [
            TextButton(
              onPressed: () async {
                List<String>? list = await AndroidSerialPort.serialPortList();
                print(list);
              },
              child: Text(
                "哈哈",
                style: TextStyle(fontSize: 30),
              ),
            ),
            TextButton(
              onPressed: () async {
                AndroidSerialPort port = AndroidSerialPort("dev/ttyS3");
                bool success = await port.open();
                if (success) {
                  print("串口打开成功");
                }
              },
              child: Text(
                "打开",
                style: TextStyle(fontSize: 30),
              ),
            )
          ],
        ),
      ),
    );
  }

  ///dev/ttyS3
}
