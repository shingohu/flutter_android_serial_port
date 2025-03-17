package com.shingo.android_serial_port;

import android.serialport.SerialPortFinder;

import java.io.IOException;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public class AndroidSerialPort extends Thread {
    private Map<String, SerialPortThread> _serialPortMap = new LinkedHashMap<>();

    private SerialPortFinder serialPortFinder = new SerialPortFinder();

    void closeAll() {
        for (SerialPortThread serialPort : _serialPortMap.values()) {
            serialPort.close();
        }
        _serialPortMap.clear();
    }


    public void close(String portPath) {
        if (_serialPortMap.containsKey(portPath)) {
            _serialPortMap.get(portPath).close();
            _serialPortMap.remove(portPath);
        }
    }

    public boolean open(SerialPortDataListener listener, String portPath, int baudrate, int stopBits, int dataBits, int parity, int flowCon, int flags) {
        if (_serialPortMap.containsKey(portPath)) {
            return true;
        }
        SerialPortThread serialPort = new SerialPortThread(listener);
        try {
            serialPort.open(portPath, baudrate, stopBits, dataBits, parity, flowCon, flags);
            _serialPortMap.put(portPath, serialPort);
            return true;
        } catch (IOException e) {
            e.printStackTrace();
        }
        return false;
    }


    public boolean write(String portPath, byte[] data) {
        if (_serialPortMap.containsKey(portPath)) {
            return _serialPortMap.get(portPath).write(data);
        }
        return false;
    }

    public List<String> serialPortList() {
        return Arrays.asList(serialPortFinder.getAllDevicesPath());
    }

}
