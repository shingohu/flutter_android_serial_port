import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

_AndroidSerialPortStream _stream = _AndroidSerialPortStream._();

class _AndroidSerialPortStream {
  static EventChannel get _streamChannel => const EventChannel('android_serial_port.stream');

  _AndroidSerialPortStream._() {
    _streamChannel.receiveBroadcastStream().cast<Map?>().listen((data) {
      String portPath = data?['portPath'];
      Uint8List result = data?['data'];
      _callbacks.forEach((callback) {
        callback(portPath, result);
      });
    });
  }

  List<Function(String, Uint8List)> _callbacks = [];

  void addCallback(Function(String, Uint8List) callback) {
    _callbacks.add(callback);
  }

  void removeCallback(Function(String, Uint8List) callback) {
    _callbacks.remove(callback);
  }
}

///only support android
class AndroidSerialPort {
  static MethodChannel get _channel => const MethodChannel('android_serial_port');

  static List<String>? _serialPortList;

  StreamController<Uint8List> _dataStreamController = StreamController.broadcast();

  ///串口数据流
  Stream<Uint8List>? get dataStream => _dataStreamController?.stream;

  StreamSubscription? _dataStreamSubscription;

  ///串口路径
  final String portPath;

  int get fd => _fd;
  int _fd = -1;

  bool get isOpen => _isOpen;
  bool _isOpen = false;

  AndroidSerialPort(this.portPath) {
    if (Platform.isAndroid) {
      _stream.addCallback(_dataCallback);
    }
  }

  void _dataCallback(String portPath, Uint8List data) {
    if (this.portPath == portPath) {
      _dataStreamController?.add(data);
    }
  }

  ///打开串口
  Future<bool> open({int baudRate = 9600,
    int dataBits = 8,
    int stopBits = 1,
    int flowControl = 0,
    int parity = 0,
    //没有数据时等待时间
    int waitMs = 0,
    int flag = 0}) async {
    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod('open', {
          'portPath': portPath,
          'baudRate': baudRate,
          'dataBits': dataBits,
          'stopBits': stopBits,
          'parity': parity,
          'waitMs': waitMs,
          'flowControl': flowControl,
          'flags': flag
        });
        _isOpen = true;
        _fd = await _channel.invokeMethod("getFd", {
          "portPath": portPath
        });
      } on PlatformException catch (e) {
        print(e.message);
        _isOpen = false;
        _fd = -1;
      }
    }
    return _isOpen;
  }

  ///关闭串口
  Future<void> close() async {
    if (Platform.isAndroid) {
      _fd = -1;
      return await _channel.invokeMethod('close', {'portPath': portPath});
    }
  }

  Future<void> dispose() async {
    if (Platform.isAndroid) {
      await _channel.invokeMethod('close', {'portPath': portPath});
      _dataStreamSubscription?.cancel();
      _dataStreamSubscription = null;
      _dataStreamController.close();
      _fd = -1;
      _stream.removeCallback(_dataCallback);
    }
  }

  ///写入数据
  Future<bool> write(Uint8List data) async {
    if (Platform.isAndroid) {
      return await _channel.invokeMethod<bool>('write', {'portPath': portPath, 'data': data}) ?? false;
    }
    return false;
  }

  ///关闭所有串口
  static Future<void> hotRestart() async {
    if (Platform.isAndroid) {
      return await _channel.invokeMethod('hotRestart');
    }
  }

  ///通过FD关闭串口
  static Future<void> closeByFd(int fd) async {
    if (Platform.isAndroid) {
      return await _channel.invokeMethod("closeByFd", {
        "fd": fd
      });
    }
  }

  ///串口列表
  static Future<List<String>> serialPortList() async {
    if (Platform.isAndroid) {
      if (_serialPortList == null) {
        _serialPortList =
            (await _channel.invokeMethod<List>('serialPortList'))?.map((e) => e.toString()).toList() ?? [];
      }
      return _serialPortList!;
    }
    return [];
  }
}
