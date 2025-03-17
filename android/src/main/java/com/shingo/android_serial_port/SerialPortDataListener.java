package com.shingo.android_serial_port;

public interface SerialPortDataListener {

    void onReceiveData(String portPath, byte[] data);
}
