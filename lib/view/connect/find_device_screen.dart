import 'dart:async';

import 'package:e_fever_care/view/main_page.dart';
import 'package:e_fever_care/view/widgets/scan_result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';

import '../../controller/connect_page_controller.dart';

class FindDevicesScreen extends GetView<ConnectPageController> {
  const FindDevicesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Koneksikan Perangkat',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        foregroundColor: Colors.teal,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () {
          controller.update();
          if (FlutterBluePlus.isScanningNow == false) {
            FlutterBluePlus.startScan(
                timeout: const Duration(seconds: 15),
                androidUsesFineLocation: false);
          }
          return Future.delayed(const Duration(milliseconds: 500));
        },
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              // daftar device yg sudah terkoneksi
              StreamBuilder<List<BluetoothDevice>>(
                stream:
                Stream.fromFuture(FlutterBluePlus.connectedSystemDevices),
                initialData: const [],
                builder: (c, snapshot) => Column(
                  children: (snapshot.data ?? [])
                      .map((d) => ListTile(
                    title: Text(d.platformName),
                    subtitle: Text(d.remoteId.toString()),
                    trailing: StreamBuilder<BluetoothConnectionState>(
                      stream: d.connectionState,
                      initialData:
                      BluetoothConnectionState.disconnected,
                      builder: (c, snapshot) {
                        if (snapshot.data ==
                            BluetoothConnectionState.connected) {
                          return ElevatedButton(
                            child: const Text('DISCONNECT'),
                            onPressed: () async {
                              try {
                                await controller.sendDisconnectDevice();

                                Get.snackbar(
                                  "Info",
                                  "Meminta perangkat untuk disconnect...",
                                  margin: const EdgeInsets.all(8),
                                  icon: const Icon(Icons.info, color: Colors.blue),
                                );

                                await d.disconnect(timeout: 20);

                                d.connectionState.listen((state) async {
                                  if (state == BluetoothConnectionState.disconnected) {
                                    Get.snackbar(
                                      "Success",
                                      "Perangkat terputus",
                                      margin: const EdgeInsets.all(8),
                                      icon: const Icon(Icons.verified_rounded, color: Colors.green),
                                    );
                                    final bondState = await d.bondState.first;
                                    if (bondState == BluetoothBondState.bonded) {
                                      print("🔓 Removing bond...");
                                      await d.removeBond();
                                      await Future.delayed(const Duration(seconds: 2));
                                    }
                                    await controller.et570Stream.cancel();
                                  }
                                });
                              } catch (e) {
                                Get.snackbar(
                                  "Error",
                                  "Disconnect error $e",
                                  margin: const EdgeInsets.all(8),
                                  icon: const Icon(Icons.error, color: Colors.red),
                                );
                              }
                            },
                          );
                        }
                        if (snapshot.data ==
                            BluetoothConnectionState.disconnected) {
                          return ElevatedButton(
                            child: const Text('CONNECT'),
                            onPressed: () {
                              d.connect(
                                  timeout: const Duration(seconds: 35))
                                  .catchError((e) {
                                Get.snackbar(
                                  "Error",
                                  "Connect error $e",
                                  margin: const EdgeInsets.all(8),
                                  icon: const Icon(Icons.error, color: Colors.red),
                                );
                              }).then((v) async {
                                try {
                                  d.discoverServices().then((services) {
                                    controller.setupET570Notifications(services);
                                    controller.saveDeviceToHive(d.remoteId.toString());
                                    Get.snackbar(
                                      "Success",
                                      "Koneksi berhasil",
                                      margin: const EdgeInsets.all(8),
                                      icon: const Icon(Icons.verified_rounded, color: Colors.green),
                                    );
                                  });
                                } catch (e) {
                                  Get.snackbar(
                                    "Error",
                                    "Koneksi error $e",
                                    margin: const EdgeInsets.all(8),
                                    icon: const Icon(Icons.error, color: Colors.red),
                                  );
                                }
                              }).then((v) {
                                Get.to(() => const MainPage());
                              });
                            },
                          );
                        }
                        return Text(snapshot.data
                            .toString()
                            .toUpperCase()
                            .split('.')[1]);
                      },
                    ),
                  ))
                      .toList(),
                ),
              ),
              StreamBuilder<List<ScanResult>>(
                stream: FlutterBluePlus.scanResults,
                initialData: const [],
                builder: (context, snapshot) {
                  return FutureBuilder<List<BluetoothDevice>>(
                    future: FlutterBluePlus.connectedSystemDevices,
                    builder: (context, connectedSnapshot) {
                      if (!connectedSnapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final connectedDevices = connectedSnapshot.data!;
                      final filteredResults = (snapshot.data ?? []).where((r) {
                        final isConnected = connectedDevices.any((d) => d.remoteId == r.device.remoteId);
                        return !isConnected;
                      }).toList();

                      return Column(
                        children: filteredResults.map((r) {
                          return ScanResultTile(
                            result: r,
                            onTap: () async {
                              try {
                                await r.device.connect(timeout: const Duration(seconds: 30));

                                final services = await r.device.discoverServices();
                                controller.setupET570Notifications(services);
                                controller.saveDeviceToHive(r.device.remoteId.toString());

                                Get.snackbar(
                                  "Success",
                                  "Koneksi berhasil",
                                  margin: const EdgeInsets.all(8),
                                  icon: const Icon(Icons.verified_rounded, color: Colors.green),
                                );

                                Get.to(() => const MainPage(), arguments: 3);
                              } catch (e) {
                                Get.snackbar(
                                  "Error",
                                  "Connect error $e",
                                  margin: const EdgeInsets.all(8),
                                  icon: const Icon(Icons.error, color: Colors.red),
                                );
                              }
                            },
                          );
                        }).toList(),
                      );
                    },
                  );
                },
              )
            ],
          ),
        ),
      ),
      floatingActionButton: StreamBuilder<bool>(
        stream: FlutterBluePlus.isScanning,
        initialData: false,
        builder: (c, snapshot) {
          if (snapshot.data ?? false) {
            return FloatingActionButton(
              onPressed: () async {
                try {
                  await FlutterBluePlus.stopScan();
                } catch (e) {
                  Get.snackbar(
                    "Error",
                    "Stop Scan Error $e",
                    colorText: Colors.white,
                    backgroundColor: Colors.red,
                    margin: const EdgeInsets.all(8),
                    icon: const Icon(Icons.error, color: Colors.red),
                  );
                }
              },
              child: const Icon(Icons.stop),
            );
          } else {
            return FloatingActionButton(
              child: const Text("SCAN"),
              onPressed: () async {
                try {
                  await FlutterBluePlus.startScan(
                    timeout: const Duration(seconds: 15),
                    androidUsesFineLocation: false,
                    withServices: [Guid("0000fee7-0000-1000-8000-00805f9b34fb")],
                  );
                } catch (e) {
                  Get.snackbar(
                    "Error",
                    "Start Scan Error $e",
                    margin: const EdgeInsets.all(8),
                    icon: const Icon(Icons.error, color: Colors.red),
                  );
                }
                controller.update();
              },
            );
          }
        },
      ),
    );
  }
}