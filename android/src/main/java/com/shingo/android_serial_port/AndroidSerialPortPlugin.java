package com.shingo.android_serial_port;

import android.os.Handler;
import android.os.Looper;

import androidx.annotation.NonNull;

import java.util.HashMap;
import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

/**
 * AndroidSerialPortPlugin
 */
public class AndroidSerialPortPlugin implements FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler, SerialPortDataListener {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private MethodChannel channel;
    private EventChannel serialPortStreamChannel;
    private EventChannel.EventSink serialPortStreamSink;
    private Handler uiHandler = new Handler(Looper.getMainLooper());
    private AndroidSerialPort androidSerialPort = new AndroidSerialPort();

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "android_serial_port");
        channel.setMethodCallHandler(this);
        serialPortStreamChannel = new EventChannel(flutterPluginBinding.getBinaryMessenger(), "android_serial_port.stream");
        serialPortStreamChannel.setStreamHandler(this);
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        String method = call.method;
        if ("open".equals(method)) {
            String portPath = call.argument("portPath");
            int baudRate = call.argument("baudRate");
            int dataBits = call.argument("dataBits");
            int stopBits = call.argument("stopBits");
            int parity = call.argument("parity");
            int flowControl = call.argument("flowControl");
            int flags = call.argument("flags");
            int waitMs = call.argument("waitMs");
            boolean success = androidSerialPort.open(this, portPath, baudRate, stopBits, dataBits, parity, flowControl, flags,waitMs);
            if (success) {
                result.success(true);
            } else {
                result.error("-1", "open serial port failed", null);
            }
        } else if ("close".equals(method)) {
            String portPath = call.argument("portPath");
            androidSerialPort.close(portPath);
            result.success(true);
        } else if ("hotRestart".equals(method)) {
            closeAll();
            result.success(true);
        } else if ("write".equals(method)) {
            String portPath = call.argument("portPath");
            byte[] bytes = call.argument("data");
            result.success(androidSerialPort.write(portPath, bytes));
        } else if ("serialPortList".equals(method)) {
            result.success(androidSerialPort.serialPortList());
        }
    }

    public void closeAll() {
        androidSerialPort.closeAll();
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        closeAll();
        channel.setMethodCallHandler(null);
        serialPortStreamChannel.setStreamHandler(null);
        serialPortStreamSink = null;
    }

    @Override
    public void onListen(Object arguments, EventChannel.EventSink events) {
        serialPortStreamSink = events;
    }

    @Override
    public void onCancel(Object arguments) {
        serialPortStreamSink = null;
    }

    @Override
    public void onReceiveData(String portPath, byte[] data) {
        if (serialPortStreamSink != null) {
            uiHandler.post(() -> {
                if (serialPortStreamSink != null) {
                    Map<String, Object> arg = new HashMap<>();
                    arg.put("portPath", portPath);
                    arg.put("data", data);
                    serialPortStreamSink.success(arg);
                }
            });
        }
    }
}
