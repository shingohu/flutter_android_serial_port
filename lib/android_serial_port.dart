import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

///only support android
class AndroidSerialPort {
  static MethodChannel get _channel =>
      const MethodChannel('android_serial_port');

  static List<String>? _serialPortList;

  EventChannel get _streamChannel =>
      const EventChannel('android_serial_port.stream');
  StreamController<Uint8List>? _dataStreamController;

  ///串口数据流
  Stream<Uint8List>? get dataStream => _dataStreamController?.stream;

  StreamSubscription? _dataStreamSubscription;

  ///串口路径
  final String portPath;

  bool get isOpen => _isOpen;
  bool _isOpen = false;

  AndroidSerialPort(this.portPath) {
    if (Platform.isAndroid) {
      _dataStreamController = StreamController.broadcast();
      _dataStreamSubscription =
          _streamChannel.receiveBroadcastStream().cast<Map?>().listen((data) {
            String portPath = data?['portPath'];
            if (portPath == this.portPath) {
              _dataStreamController?.add(data?['data']);
            }
          });
    }
  }

  ///打开串口
  Future<bool> open({int baudRate = 9600,
    int dataBits = 8,
    int stopBits = 1,
    int flowControl = 0,
    int parity = 0,
    int flag = 0}) async {
    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('open', {
          'portPath': portPath,
          'baudRate': baudRate,
          'dataBits': dataBits,
          'stopBits': stopBits,
          'parity': parity,
          'flowControl': flowControl,
          'flags': flag
        });
        _isOpen = true;
      } on PlatformException catch (e) {
        print(e.message);
        _isOpen = false;
      }
    }
    return _isOpen;
  }

  ///关闭串口
  Future<void> close() async {
    if (Platform.isAndroid) {
      return await _channel.invokeMethod('close', {'portPath': portPath});
    }
  }

  Future<void> dispose() async {
    if (Platform.isAndroid) {
      await _channel.invokeMethod('close', {'portPath': portPath});
      _dataStreamSubscription?.cancel();
      _dataStreamSubscription = null;
      _dataStreamController?.close();
    }
  }

  ///写入数据
  Future<bool> write(Uint8List data) async {
    if (Platform.isAndroid) {
      return await _channel.invokeMethod<bool>(
          'write', {'portPath': portPath, 'data': data}) ??
          false;
    }
    return false;
  }

  ///关闭所有串口
  static Future<void> hotRestart() async {
    if (Platform.isAndroid) {
      return await _channel.invokeMethod('hotRestart');
    }
  }

  ///串口列表
  static Future<List<String>> serialPortList() async {
    if (Platform.isAndroid) {
      if (_serialPortList == null) {
        _serialPortList = (await _channel.invokeMethod<List>('serialPortList'))
            ?.map((e) => e.toString())
            .toList() ??
            [];
      }
      return _serialPortList!;
    }
    return [];
  }
}
