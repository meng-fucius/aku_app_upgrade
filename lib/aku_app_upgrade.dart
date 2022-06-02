library aku_app_upgrade;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

enum ForceUpgrade {
  force(1),
  unForce(2);

  final int typeNum;

  static ForceUpgrade getValue(int value) =>
      ForceUpgrade.values.firstWhere((element) => element.typeNum == value);

  const ForceUpgrade(this.typeNum);
}

class AppUpgrade {
  static final AppUpgrade _instance = AppUpgrade._();

  factory AppUpgrade() => _instance;

  AppUpgrade._();

  Future checkUpgrade(
    BuildContext context, {
    Function(String)? onError,
    Function(Map)? onRequestFail,
    Function()? onLaunchFail,
  }) async {
    WidgetsFlutterBinding.ensureInitialized();
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    int buildNo = int.parse(packageInfo.buildNumber);

    if (kDebugMode) {
      print('当前版本号：${packageInfo.version}${packageInfo.buildNumber}');
    }
    Response? response;
    try {
      response = await Dio().get(
          'http://121.41.26.225:8006/app/version/findNewVersion',
          queryParameters: {'buildNo': buildNo});
    } catch (e) {
      onError?.call(e.toString());
      return;
    }
    if (kDebugMode) {
      print('查询最新版本结果：${response.data}');
    }
    if (response.data['success']) {
      AkuAppVersion akuAppVersion =
          AkuAppVersion.fromMap(response.data['data']);
      if (buildNo < akuAppVersion.buildNo) {
        await showDialog(
            context: context,
            barrierDismissible: akuAppVersion.forceEM != ForceUpgrade.force,
            builder: (context) {
              return WillPopScope(
                  onWillPop: () async {
                    return akuAppVersion.forceEM != ForceUpgrade.force;
                  },
                  child: upgradeDialog(
                      context, packageInfo, onLaunchFail, akuAppVersion));
            });
      }
    } else {
      onRequestFail?.call(response.data);
    }
  }

  upgradeDialog(BuildContext context, PackageInfo packageInfo,
      Function()? onLaunchFail, AkuAppVersion akuAppVersion) {
    return Center(
      child: Material(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 300,
          height: 200,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              // gradient: LinearGradient(colors: [
              //   Colors.yellow.withOpacity(0.05),
              //   Colors.white,
              // ], begin: Alignment.topCenter, end: Alignment.bottomCenter),
              color: Colors.white,
              boxShadow: const [
                BoxShadow(
                  color: Colors.blue,
                  blurRadius: 5,
                  spreadRadius: 0,
                )
              ]),
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  '当前不是最新版本\n请升级最新版',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const Spacer(),
              Container(
                height: 1,
                width: double.infinity,
                color: Colors.black.withOpacity(0.45),
              ),
              SizedBox(
                height: 50,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (akuAppVersion.forceEM != ForceUpgrade.force)
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text(
                            '取消',
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: 20,
                                fontWeight: FontWeight.normal),
                          ),
                        ),
                      ),
                    Offstage(
                      offstage: akuAppVersion.forceEM == ForceUpgrade.force,
                      child: Container(
                        height: double.infinity,
                        width: 1,
                        color: Colors.black.withOpacity(0.45),
                      ),
                    ),
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          if (Platform.isAndroid) {
                            var re = await launchUrlString(
                                'mimarket://detail?id=${packageInfo.packageName}');
                            if (!re && onLaunchFail != null) {
                              onLaunchFail.call();
                            }
                          } else if (Platform.isIOS) {
                            launchUrlString(
                                'itms-apps://itunes.apple.com/app/${packageInfo.packageName}');
                          } else {}
                        },
                        child: const Text(
                          '去升级',
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                              fontWeight: FontWeight.normal),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AkuAppVersion {
  final int id;
  final String versionNumber;
  final int buildNo;
  final int forceUpdate;
  final String createDate;

  ForceUpgrade get forceEM => ForceUpgrade.getValue(forceUpdate);

//<editor-fold desc="Data Methods">

  const AkuAppVersion({
    required this.id,
    required this.versionNumber,
    required this.buildNo,
    required this.forceUpdate,
    required this.createDate,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AkuAppVersion &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          versionNumber == other.versionNumber &&
          buildNo == other.buildNo &&
          forceUpdate == other.forceUpdate &&
          createDate == other.createDate);

  @override
  int get hashCode =>
      id.hashCode ^
      versionNumber.hashCode ^
      buildNo.hashCode ^
      forceUpdate.hashCode ^
      createDate.hashCode;

  @override
  String toString() {
    return 'AkuAppVersion{ id: $id, versionNumber: $versionNumber, buildNo: $buildNo, forceUpdate: $forceUpdate, createDate: $createDate,}';
  }

  AkuAppVersion copyWith({
    int? id,
    String? versionNumber,
    int? buildNo,
    int? forceUpdate,
    String? createDate,
  }) {
    return AkuAppVersion(
      id: id ?? this.id,
      versionNumber: versionNumber ?? this.versionNumber,
      buildNo: buildNo ?? this.buildNo,
      forceUpdate: forceUpdate ?? this.forceUpdate,
      createDate: createDate ?? this.createDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'versionNumber': versionNumber,
      'buildNo': buildNo,
      'forceUpdate': forceUpdate,
      'createDate': createDate,
    };
  }

  factory AkuAppVersion.fromMap(Map<String, dynamic> map) {
    return AkuAppVersion(
      id: map['id'] as int,
      versionNumber: map['versionNumber'] as String,
      buildNo: map['buildNo'] as int,
      forceUpdate: map['forceUpdate'] as int,
      createDate: map['createDate'] as String,
    );
  }

//</editor-fold>
}
