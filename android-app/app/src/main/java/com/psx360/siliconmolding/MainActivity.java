package com.psx360.siliconmolding;

import android.Manifest;
import android.app.Activity;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothGatt;
import android.bluetooth.BluetoothGattCallback;
import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothGattService;
import android.bluetooth.BluetoothManager;
import android.bluetooth.BluetoothProfile;
import android.bluetooth.le.BluetoothLeScanner;
import android.bluetooth.le.ScanCallback;
import android.bluetooth.le.ScanResult;
import android.content.Context;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.graphics.Color;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.text.InputType;
import android.view.Gravity;
import android.view.View;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.CheckBox;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.ListView;
import android.widget.TextView;
import android.widget.Toast;

import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;

public class MainActivity extends Activity {
    private static final String PREFS = "silicon_molding";
    private static final String PREF_DEVICE_ID = "device_id";
    private static final String PREF_SPEED = "speed";
    private static final String PREF_REVOLUTIONS = "revolutions";
    private static final UUID SERVICE_UUID = UUID.fromString("6c8b5a90-7d2c-4c5e-98df-24a16d8a1001");
    private static final UUID WRITE_UUID = UUID.fromString("6c8b5a91-7d2c-4c5e-98df-24a16d8a1001");
    private static final int REQUEST_PERMISSIONS = 100;

    private final Handler handler = new Handler(Looper.getMainLooper());
    private final Map<String, BluetoothDevice> devices = new LinkedHashMap<>();
    private ArrayAdapter<String> deviceAdapter;
    private BluetoothLeScanner scanner;
    private BluetoothGatt gatt;
    private BluetoothGattCharacteristic writeCharacteristic;
    private SharedPreferences prefs;
    private TextView statusView;
    private boolean connected;

    private final Runnable pingRunnable = new Runnable() {
        @Override
        public void run() {
            if (connected) {
                sendCommand("PING");
            }
            updateStatus(connected);
            handler.postDelayed(this, 1500);
        }
    };

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        prefs = getSharedPreferences(PREFS, MODE_PRIVATE);
        if (!hasBlePermission()) {
            requestBlePermissions();
            showConnectingScreen("Нужны разрешения Bluetooth");
            return;
        }

        openInitialScreen();
    }

    private void openInitialScreen() {
        String savedDeviceId = prefs.getString(PREF_DEVICE_ID, null);
        if (savedDeviceId != null) {
            BluetoothAdapter adapter = getBluetoothAdapter();
            if (adapter != null) {
                showConnectingScreen("Подключение к сохраненному устройству...");
                connect(adapter.getRemoteDevice(savedDeviceId), false);
                return;
            }
        }

        showScanScreen();
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        if (requestCode == REQUEST_PERMISSIONS && hasBlePermission()) {
            openInitialScreen();
        } else if (requestCode == REQUEST_PERMISSIONS) {
            toast("Bluetooth разрешения не выданы");
            showScanScreen();
        }
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        handler.removeCallbacksAndMessages(null);
        stopScan();
        closeGatt();
    }

    private void requestBlePermissions() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            requestPermissions(new String[] {
                    Manifest.permission.BLUETOOTH_SCAN,
                    Manifest.permission.BLUETOOTH_CONNECT
            }, REQUEST_PERMISSIONS);
        } else {
            requestPermissions(new String[] { Manifest.permission.ACCESS_FINE_LOCATION }, REQUEST_PERMISSIONS);
        }
    }

    private BluetoothAdapter getBluetoothAdapter() {
        BluetoothManager manager = (BluetoothManager) getSystemService(Context.BLUETOOTH_SERVICE);
        return manager == null ? null : manager.getAdapter();
    }

    private void showScanScreen() {
        closeGatt();
        handler.removeCallbacks(pingRunnable);

        LinearLayout root = rootLayout();
        TextView title = title("Bluetooth BLE устройства");
        Button refresh = button("Обновить");
        ListView list = new ListView(this);

        deviceAdapter = new ArrayAdapter<>(this, android.R.layout.simple_list_item_1, new ArrayList<String>());
        list.setAdapter(deviceAdapter);
        list.setOnItemClickListener(new AdapterView.OnItemClickListener() {
            @Override
            public void onItemClick(AdapterView<?> parent, View view, int position, long id) {
                String row = deviceAdapter.getItem(position);
                BluetoothDevice device = devices.get(row);
                if (device != null) {
                    showConnectingScreen("Подключение к " + displayName(device) + "...");
                    connect(device, true);
                }
            }
        });

        refresh.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                startScan();
            }
        });

        root.addView(title);
        root.addView(refresh);
        root.addView(list, new LinearLayout.LayoutParams(-1, 0, 1));
        setContentView(root);
        startScan();
    }

    private void showConnectingScreen(String message) {
        LinearLayout root = rootLayout();
        TextView text = title(message);
        root.setGravity(Gravity.CENTER);
        root.addView(text);
        setContentView(root);
    }

    private void showMainScreen() {
        handler.removeCallbacks(pingRunnable);
        LinearLayout root = rootLayout();

        LinearLayout top = new LinearLayout(this);
        top.setOrientation(LinearLayout.HORIZONTAL);
        top.setGravity(Gravity.CENTER_VERTICAL);
        statusView = new TextView(this);
        statusView.setTextSize(18);
        Button back = button("Назад");
        top.addView(statusView, new LinearLayout.LayoutParams(0, -2, 1));
        top.addView(back);

        EditText speed = numberInput("Скорость, об/мин 1-500", prefs.getString(PREF_SPEED, "100"));
        CheckBox reverse = new CheckBox(this);
        reverse.setText("Обратное направление");
        reverse.setTextSize(18);
        EditText revolutions = decimalInput("Количество оборотов 0.01-1000", prefs.getString(PREF_REVOLUTIONS, "50"));
        Button run = button("Поехали");
        Button stop = button("Стоп");

        back.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                prefs.edit().remove(PREF_DEVICE_ID).apply();
                showScanScreen();
            }
        });

        run.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                int speedValue = clamp(parseInt(speed.getText().toString(), 100), 1, 500);
                float revolutionsValue = clamp(parseFloat(revolutions.getText().toString(), 50.0f), 0.01f, 1000.0f);
                speed.setText(String.valueOf(speedValue));
                revolutions.setText(formatFloat(revolutionsValue));
                prefs.edit()
                        .putString(PREF_SPEED, String.valueOf(speedValue))
                        .putString(PREF_REVOLUTIONS, formatFloat(revolutionsValue))
                        .apply();
                sendCommand("RUN:" + speedValue + ":" + (reverse.isChecked() ? 1 : 0) + ":" + revolutionsValue);
            }
        });

        stop.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                sendCommand("STOP");
            }
        });

        root.addView(top);
        root.addView(speed);
        root.addView(reverse);
        root.addView(revolutions);
        root.addView(run);
        root.addView(stop);
        setContentView(root);
        updateStatus(true);
        handler.post(pingRunnable);
    }

    private LinearLayout rootLayout() {
        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setPadding(32, 32, 32, 32);
        return root;
    }

    private TextView title(String text) {
        TextView view = new TextView(this);
        view.setText(text);
        view.setTextSize(22);
        view.setPadding(0, 0, 0, 24);
        return view;
    }

    private Button button(String text) {
        Button button = new Button(this);
        button.setText(text);
        return button;
    }

    private EditText numberInput(String hint, String value) {
        EditText input = new EditText(this);
        input.setHint(hint);
        input.setText(value);
        input.setTextSize(18);
        input.setInputType(InputType.TYPE_CLASS_NUMBER);
        return input;
    }

    private EditText decimalInput(String hint, String value) {
        EditText input = numberInput(hint, value);
        input.setInputType(InputType.TYPE_CLASS_NUMBER | InputType.TYPE_NUMBER_FLAG_DECIMAL);
        return input;
    }

    private void startScan() {
        if (!hasBlePermission()) {
            requestBlePermissions();
            return;
        }

        BluetoothAdapter adapter = getBluetoothAdapter();
        if (adapter == null || !adapter.isEnabled()) {
            toast("Bluetooth выключен");
            return;
        }

        devices.clear();
        if (deviceAdapter != null) {
            deviceAdapter.clear();
        }

        scanner = adapter.getBluetoothLeScanner();
        if (scanner != null) {
            scanner.startScan(scanCallback);
            handler.postDelayed(new Runnable() {
                @Override
                public void run() {
                    stopScan();
                }
            }, 10000);
        }
    }

    private void stopScan() {
        if (scanner != null && hasBlePermission()) {
            scanner.stopScan(scanCallback);
        }
    }

    private final ScanCallback scanCallback = new ScanCallback() {
        @Override
        public void onScanResult(int callbackType, ScanResult result) {
            BluetoothDevice device = result.getDevice();
            String row = displayName(device) + "  " + device.getAddress();
            if (!devices.containsKey(row)) {
                devices.put(row, device);
                if (deviceAdapter != null) {
                    deviceAdapter.add(row);
                }
            }
        }
    };

    private void connect(BluetoothDevice device, boolean saveOnSuccess) {
        if (!hasBlePermission()) {
            requestBlePermissions();
            return;
        }
        stopScan();
        closeGatt();
        gatt = device.connectGatt(this, false, new BluetoothGattCallback() {
            @Override
            public void onConnectionStateChange(BluetoothGatt gatt, int status, int newState) {
                connected = newState == BluetoothProfile.STATE_CONNECTED;
                if (connected) {
                    gatt.discoverServices();
                } else {
                    handler.post(new Runnable() {
                        @Override
                        public void run() {
                            updateStatus(false);
                            showScanScreen();
                        }
                    });
                }
            }

            @Override
            public void onServicesDiscovered(BluetoothGatt gatt, int status) {
                BluetoothGattService service = gatt.getService(SERVICE_UUID);
                writeCharacteristic = service == null ? null : service.getCharacteristic(WRITE_UUID);
                if (writeCharacteristic == null) {
                    connected = false;
                    handler.post(new Runnable() {
                        @Override
                        public void run() {
                            toast("Устройство не поддерживает протокол");
                            showScanScreen();
                        }
                    });
                    return;
                }
                if (saveOnSuccess) {
                    prefs.edit().putString(PREF_DEVICE_ID, gatt.getDevice().getAddress()).apply();
                }
                handler.post(new Runnable() {
                    @Override
                    public void run() {
                        showMainScreen();
                    }
                });
            }
        });
    }

    private void sendCommand(String command) {
        if (!connected || gatt == null || writeCharacteristic == null || !hasBlePermission()) {
            updateStatus(false);
            return;
        }
        writeCharacteristic.setValue((command + "\n").getBytes(StandardCharsets.UTF_8));
        boolean ok = gatt.writeCharacteristic(writeCharacteristic);
        updateStatus(ok);
    }

    private void updateStatus(boolean isConnected) {
        connected = isConnected;
        if (statusView != null) {
            statusView.setText(isConnected ? "Bluetooth: подключен" : "Bluetooth: не подключен");
            statusView.setTextColor(isConnected ? Color.rgb(16, 140, 65) : Color.rgb(190, 30, 30));
        }
    }

    private void closeGatt() {
        if (gatt != null && hasBlePermission()) {
            gatt.close();
        }
        gatt = null;
        writeCharacteristic = null;
        connected = false;
    }

    private boolean hasBlePermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            return checkSelfPermission(Manifest.permission.BLUETOOTH_SCAN) == PackageManager.PERMISSION_GRANTED
                    && checkSelfPermission(Manifest.permission.BLUETOOTH_CONNECT) == PackageManager.PERMISSION_GRANTED;
        }
        return checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED;
    }

    private String displayName(BluetoothDevice device) {
        if (!hasBlePermission()) {
            return "BLE устройство";
        }
        String name = device.getName();
        return name == null || name.length() == 0 ? "Без имени" : name;
    }

    private int parseInt(String text, int fallback) {
        try {
            return Integer.parseInt(text);
        } catch (NumberFormatException ignored) {
            return fallback;
        }
    }

    private float parseFloat(String text, float fallback) {
        try {
            return Float.parseFloat(text.replace(',', '.'));
        } catch (NumberFormatException ignored) {
            return fallback;
        }
    }

    private int clamp(int value, int min, int max) {
        return Math.max(min, Math.min(max, value));
    }

    private float clamp(float value, float min, float max) {
        return Math.max(min, Math.min(max, value));
    }

    private String formatFloat(float value) {
        if (value == Math.round(value)) {
            return String.valueOf(Math.round(value));
        }
        return String.valueOf(value);
    }

    private void toast(String message) {
        Toast.makeText(this, message, Toast.LENGTH_SHORT).show();
    }
}
