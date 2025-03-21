package com.shingo.android_serial_port;

import android.serialport.SerialPort;
import android.util.Log;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.util.HashMap;
import java.util.Map;

public class SerialPortThread extends Thread {

    private SerialPort serialPort;

    private SerialPortDataListener dataListener;
    private boolean isClose = true;

    public void close() {
        if (serialPort != null) {
            isClose = true;
            serialPort.tryClose();
            interrupt();
        }
    }

    public SerialPortThread(SerialPortDataListener dataListener) {
        this.dataListener = dataListener;
    }

    public void open(String path, int baudrate, int stopBits, int dataBits, int parity, int flowCon, int flags) throws IOException {
        serialPort = new SerialPort(new File(path), baudrate, stopBits, dataBits, parity, flowCon, flags);
        isClose = false;
        start();
    }

    public boolean write(byte[] data) {
        try {
            if (serialPort != null && !isClose) {
                serialPort.getOutputStream().write(data);
            }
            return true;
        } catch (IOException e) {
            e.printStackTrace();
        }
        return false;
    }


    @Override
    public void run() {
        InputStream inputStream = serialPort.getInputStream();
        String path = serialPort.getPortPath();
        while (!isInterrupted() && !isClose) {
            try {
                if (inputStream == null) return;
                byte[] buffer;
                int im = inputStream.available();
                if (im > 0) {
                    buffer = new byte[im];
                    int size = inputStream.read(buffer);
                    if (dataListener != null && size > 0) {
                        dataListener.onReceiveData(path, buffer);
                    }
                } else {
                    // Thread.sleep(50);
                }
            } catch (Exception e) {
                // e.printStackTrace();
            }
        }
    }
}
