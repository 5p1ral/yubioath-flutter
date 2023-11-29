/*
 * Copyright (C) 2022 Yubico.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *       http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:yubico_authenticator/app/views/keys.dart' as app_keys;
import 'package:yubico_authenticator/app/views/keys.dart';
import 'package:yubico_authenticator/core/state.dart';
import 'package:yubico_authenticator/management/views/keys.dart';

import 'android/util.dart' as android_test_util;
import 'desktop/util.dart' as desktop_test_util;

const shortWaitMs = 200;
const longWaitMs = 500;
const ultraLongWaitMs = 5000;

/// information about YubiKey as seen by the app
String? yubiKeyName;
String? yubiKeyFirmware;
String? yubiKeySerialNumber;
bool collectedYubiKeyInformation = false;

extension AppWidgetTester on WidgetTester {
  Future<void> shortWait() async {
    await pump(const Duration(milliseconds: shortWaitMs));
  }

  Future<void> longWait() async {
    await pump(const Duration(milliseconds: longWaitMs));
  }

  Future<void> ultraLongWait() async {
    await pump(const Duration(milliseconds: ultraLongWaitMs));
  }

  /// waits up to [timeOutSec] seconds evaluating whether [Finder] f is
  /// visible
  Future<Finder> waitForFinder(Finder f, [int timeOutSec = 20]) async {
    int delayMs = 500;
    int elapsedTime = 0;

    var evaluated = f.evaluate();
    while (evaluated.isEmpty && elapsedTime < timeOutSec * 1000) {
      await pump(Duration(milliseconds: delayMs));
      elapsedTime += delayMs;
      evaluated = f.evaluate();
    }

    if (evaluated.isEmpty) {
      testLog(false,
          'Found 0 ${f.describeMatch(Plurality.zero)} in $timeOutSec seconds.');
    }

    return f;
  }

  Finder findActionIconButton() {
    return find.byKey(actionsIconButtonKey).hitTestable();
  }

  Future<void> tapActionIconButton() async {
    await tap(findActionIconButton());
    await pump(const Duration(milliseconds: 500));
  }

  Future<void> tapTopLeftCorner() async {
    await tapAt(const Offset(0, 0));
    await longWait();
  }

  /// Drawer helpers
  bool hasDrawer() => scaffoldGlobalKey.currentState!.hasDrawer;

  /// Open drawer
  Future<void> openDrawer() async {
    if (hasDrawer()) {
      scaffoldGlobalKey.currentState!.openDrawer();
      await pump(const Duration(milliseconds: 500));
    }
  }

  /// Close drawer
  Future<void> closeDrawer() async {
    if (hasDrawer()) {
      scaffoldGlobalKey.currentState!.closeDrawer();
      await pump(const Duration(milliseconds: 500));
    }
  }

  /// Is drawer opened?
  /// If there is no drawer say it is open (all items are available)
  bool isDrawerOpened() =>
      hasDrawer() == false || scaffoldGlobalKey.currentState!.isDrawerOpen;

  /// Tap a app button in the drawer
  /// If the drawer is closed, it is opened first
  Future<void> tapAppDrawerButton(Key appKey) async {
    if (hasDrawer() && !isDrawerOpened()) {
      await openDrawer();
    }

    var appButtonFinder = find.byKey(appKey).hitTestable();
    await tap(appButtonFinder);
    await longWait();
  }

  /// Management screen
  Future<void> openManagementScreen() async {
    if (!isDrawerOpened()) {
      await openDrawer();
    }

    await tap(find.byKey(managementAppDrawer).hitTestable());
    await pump(const Duration(milliseconds: 500));

    expect(find.byKey(screenKey), findsOneWidget);
  }

  /// Retrieve a list of test approved serial numbers.
  ///
  /// There are two ways how to provide approved serial numbers:
  ///
  /// 1. Serial numbers defined in test resource file
  /// To add testing keys add comma separated serial numbers to a file
  /// `approved_serial_numbers.csv` in `integration_test/test_res/resources/`.
  /// This file is bundled only during test runs and is explicitly ignored from
  /// version control.
  ///
  /// 2. Serial numbers passed through build environment
  /// YA_TEST_APPROVED_KEY_SN should contain comma separated list of
  /// YubiKey serial numbers which are approved for tests
  /// To pass the variable to the test use:
  /// flutter --dart-define=YA_TEST_APPROVED_KEY_SN=SN1,SN2,...,SNn test t
  Future<List<String>> getApprovedSerialNumbers() async {
    const approvedKeysResource = 'approved_serial_numbers.csv';
    String approved = '';

    const envVar = String.fromEnvironment('YA_TEST_APPROVED_KEY_SN');

    try {
      approved = await rootBundle.loadString(
        'packages/test_res/resources/$approvedKeysResource',
      );
    } catch (_) {
      testLog(false, 'Failed to read $approvedKeysResource');
    }

    return (approved + (approved.isEmpty ? ',' : '') + envVar)
        .split(',')
        .map((e) => e.trim())
        .toList(growable: false);
  }

  Future<void> startUp([Map<dynamic, dynamic> startUpParams = const {}]) async {
    var result = isAndroid == true
        ? await android_test_util.startUp(this, startUpParams)
        : await desktop_test_util.startUp(this, startUpParams);

    await collectYubiKeyInformation();

    if (yubiKeySerialNumber == null) {
      fail('No YubiKey connected');
    }

    final approvedSerialNumbers = await getApprovedSerialNumbers();

    if (!approvedSerialNumbers.contains(yubiKeySerialNumber)) {
      fail('YubiKey with S/N $yubiKeySerialNumber is not approved for '
          'integration tests.\nUse --dart-define='
          'YA_TEST_APPROVED_KEY_SN=$yubiKeySerialNumber test '
          'parameter to approve it.');
    }

    return result;
  }

  void testLog(bool quiet, String message) {
    if (!quiet) {
      printToConsole(message);
    }
  }

  /// get key information
  Future<void> collectYubiKeyInformation() async {
    if (collectedYubiKeyInformation) {
      return;
    }

    await openDrawer();

    var deviceInfo = find.byKey(app_keys.deviceInfoListTile);
    if (deviceInfo.evaluate().isNotEmpty) {
      ListTile lt = find
          .descendant(of: deviceInfo, matching: find.byType(ListTile))
          .evaluate()
          .single
          .widget as ListTile;

      yubiKeyName = (lt.title as Text).data;
      var subtitle = (lt.subtitle as Text?)?.data;

      if (subtitle != null) {
        RegExpMatch? match =
            RegExp(r'S/N: (\d.*) F/W: (\d\.\d\.\d)').firstMatch(subtitle);
        if (match != null) {
          yubiKeySerialNumber = match.group(1);
          yubiKeyFirmware = match.group(2);
        } else {
          match = RegExp(r'F/W: (\d\.\d\.\d)').firstMatch(subtitle);
          if (match != null) {
            yubiKeyFirmware = match.group(1);
          }
        }
      }
    }

    // close the opened menu
    await closeDrawer();

    if (yubiKeySerialNumber != null) {
      testLog(false,
          'Connected YubiKey: $yubiKeySerialNumber/$yubiKeyFirmware - $yubiKeyName');
    }
    collectedYubiKeyInformation = true;
  }

  bool isTextButtonEnabled(Key buttonKey) {
    var finder = find.byKey(buttonKey).hitTestable();
    expect(finder.evaluate().isNotEmpty, true);
    TextButton button = finder.evaluate().single.widget as TextButton;
    return button.enabled;
  }
}

@isTest
void appTest(
  String description,
  WidgetTesterCallback callback, {
  bool? skip,
  Map startUpParams = const {},
  dynamic tags,
}) {
  testWidgets(description, skip: skip, (WidgetTester tester) async {
    await tester.startUp(startUpParams);
    await callback(tester);
  }, tags: tags);
}
