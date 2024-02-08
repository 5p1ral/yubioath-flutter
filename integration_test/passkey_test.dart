/*
 * Copyright (C) 2023 Yubico.
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

@Tags(['android', 'desktop', 'oath'])
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yubico_authenticator/app/views/keys.dart';
import 'package:yubico_authenticator/fido/keys.dart';

import 'utils/test_util.dart';

void main() {
  var binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  group('Passkey PIN tests', () {
    const _simplePin = '1111';
    const _fidoPin1 = '9473';
    const _fidoPin2 = '4781';
    appTest('Reset Key', (WidgetTester tester) async {
      await tester.tap(find.byKey(fidoPasskeysAppDrawer));
      await tester.shortWait();

      await tester.tap(find.byKey(factoryresetfido2).hitTestable());
      await tester.shortWait();
    });
    appTest('Set SimplePin', (WidgetTester tester) async {
      await tester.tap(find.byKey(fidoPasskeysAppDrawer));
      await tester.shortWait();

      await tester.tap(find.byKey(actionsIconButtonKey).hitTestable());
      await tester.shortWait();

      await tester.tap(find.byKey(managePinAction));
      await tester.shortWait();

      await tester.enterText(find.byKey(newPin), _simplePin);
      await tester.shortWait();
      await tester.enterText(find.byKey(newPin), _simplePin);
      await tester.shortWait();

      await tester.tap(find.byKey(saveButton));
      await tester.shortWait();
    });
    appTest('Change to FidoPin1', (WidgetTester tester) async {
      await tester.tap(find.byKey(fidoPasskeysAppDrawer));
      await tester.shortWait();

      await tester.tap(find.byKey(actionsIconButtonKey).hitTestable());
      await tester.shortWait();

      await tester.tap(find.byKey(managePinAction));
      await tester.shortWait();

      await tester.enterText(find.byKey(currentPin), _simplePin);
      await tester.shortWait();
      await tester.enterText(find.byKey(newPin), _fidoPin1);
      await tester.shortWait();
      await tester.enterText(find.byKey(newPin), _fidoPin1);
      await tester.shortWait();

      await tester.tap(find.byKey(saveButton));
      await tester.shortWait();
    });
    appTest('Change to FidoPin2', (WidgetTester tester) async {
      await tester.tap(find.byKey(fidoPasskeysAppDrawer));
      await tester.shortWait();

      await tester.tap(find.byKey(actionsIconButtonKey).hitTestable());
      await tester.shortWait();

      await tester.tap(find.byKey(managePinAction));
      await tester.shortWait();

      await tester.enterText(find.byKey(currentPin), _fidoPin1);
      await tester.shortWait();
      await tester.enterText(find.byKey(newPin), _fidoPin2);
      await tester.shortWait();
      await tester.enterText(find.byKey(newPin), _fidoPin2);
      await tester.shortWait();

      await tester.tap(find.byKey(saveButton));
      await tester.shortWait();
    });
    appTest('Reset Key', (WidgetTester tester) async {
      await tester.tap(find.byKey(fidoPasskeysAppDrawer));
      await tester.shortWait();

      await tester.tap(find.byKey(factoryresetfido2).hitTestable());
      await tester.shortWait();
    });
  });
}
