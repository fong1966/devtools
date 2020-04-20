// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@TestOn('vm')
import 'dart:async';

import 'package:devtools_app/src/flutter/common_widgets.dart';
import 'package:devtools_app/src/globals.dart';
import 'package:devtools_app/src/logging/flutter/logging_screen.dart';
import 'package:devtools_app/src/logging/logging_controller.dart';
import 'package:devtools_app/src/service_extensions.dart';
import 'package:devtools_app/src/service_manager.dart';
import 'package:devtools_app/src/ui/flutter/service_extension_widgets.dart';
import 'package:devtools_app/src/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../support/mocks.dart';
import 'wrappers.dart';

void main() {
  LoggingScreen screen;
  group('Logging Screen', () {
    MockLoggingController mockLoggingController;
    FakeServiceManager fakeServiceManager;

    Widget wrap(Widget widget) =>
        wrapWithControllers(widget, logging: mockLoggingController);

    setUp(() async {
      await ensureInspectorDependencies();
      mockLoggingController = MockLoggingController();
      when(mockLoggingController.data).thenReturn([]);
      when(mockLoggingController.filteredData).thenReturn([]);
      when(mockLoggingController.onLogsUpdated).thenReturn(Reporter());

      fakeServiceManager = FakeServiceManager(useFakeService: true);
      when(fakeServiceManager.connectedApp.isFlutterWebAppNow)
          .thenReturn(false);
      when(fakeServiceManager.connectedApp.isProfileBuildNow).thenReturn(false);
      setGlobal(ServiceConnectionManager, fakeServiceManager);

      screen = const LoggingScreen();
    });

    testWidgets('builds its tab', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(Builder(builder: screen.buildTab)));
      expect(find.text('Logging'), findsOneWidget);
    });

    testWidgets('builds disabled message when disabled for flutter web app',
        (WidgetTester tester) async {
      when(fakeServiceManager.connectedApp.isFlutterWebAppNow).thenReturn(true);
      when(fakeServiceManager.connectedApp.isProfileBuildNow).thenReturn(true);
      await tester.pumpWidget(wrap(Builder(builder: screen.build)));
      expect(find.byType(LoggingScreenBody), findsNothing);
      expect(find.byType(DisabledForFlutterWebProfileBuildMessage),
          findsOneWidget);
    });

    testWidgets('builds with no data', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(Builder(builder: screen.build)));
      expect(find.byType(LoggingScreenBody), findsOneWidget);
      expect(find.byType(LogsTable), findsOneWidget);
      expect(find.byType(LogDetails), findsOneWidget);
      expect(find.text('Clear'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(StructuredErrorsToggle), findsOneWidget);
    });

    testWidgets('can clear logs', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(Builder(builder: screen.build)));
      verifyNever(mockLoggingController.clear());
      await tester.tap(find.text('Clear'));
      verify(mockLoggingController.clear()).called(1);
    });

    testWidgets('can enter filter text', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(Builder(builder: screen.build)));
      verifyNever(mockLoggingController.clear());
      await tester.enterText(find.byType(TextField), 'abc');
      verify(mockLoggingController.filterText = 'abc');
    });

    testWidgets('can toggle structured errors', (WidgetTester tester) async {
      final serviceManager = FakeServiceManager();
      when(serviceManager.connectedApp.isFlutterWebAppNow).thenReturn(false);
      when(serviceManager.connectedApp.isProfileBuildNow).thenReturn(false);
      setGlobal(
        ServiceConnectionManager,
        serviceManager,
      );
      await tester.pumpWidget(wrap(Builder(builder: screen.build)));
      Switch toggle = tester.widget(find.byType(Switch));
      expect(toggle.value, false);

      serviceManager.serviceExtensionManager
          .fakeServiceExtensionStateChanged(structuredErrors.extension, 'true');
      await tester.pumpAndSettle();
      toggle = tester.widget(find.byType(Switch));
      expect(toggle.value, true);

      // TODO(djshuckerow): Hook up fake extension state querying.
    });

    group('with data', () {
      setUp(() {
        when(mockLoggingController.data).thenReturn(fakeLogData);
        when(mockLoggingController.filteredData).thenReturn(fakeLogData);
      });

      testWidgets('shows most recent logs first', (WidgetTester tester) async {
        await tester.pumpWidget(wrap(Builder(builder: screen.build)));
        await tester.pumpAndSettle();
        expect(find.byType(LogsTable), findsOneWidget);
        expect(
          find.byKey(ValueKey(fakeLogData.last)),
          findsOneWidget,
          reason: 'the most recently added logdata should show in the list by '
              'default.',
        );
        expect(
          find.byKey(ValueKey(fakeLogData.first)),
          findsNothing,
          reason:
              'the least recently added logdata should be at the top of the '
              'list, hidden from view.',
        );
      });

      testWidgets('can show non-computing log data',
          (WidgetTester tester) async {
        await tester.pumpWidget(wrap(Builder(builder: screen.build)));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(ValueKey(fakeLogData[996])));
        await tester.pumpAndSettle();
        expect(
          find.text('log event 996'),
          findsNWidgets(2),
          reason: 'The log details should be visible both in the table and the '
              'details section.',
        );
      });

      testWidgets('can show null log data', (WidgetTester tester) async {
        await tester.pumpWidget(wrap(Builder(builder: screen.build)));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(ValueKey(fakeLogData[997])));
        await tester.pumpAndSettle();
      });

      testWidgets('can compute details of non-json log data',
          (WidgetTester tester) async {
        const index = 998;
        final log = fakeLogData[index];

        await tester.pumpWidget(wrap(Builder(builder: screen.build)));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(ValueKey(log)));
        await tester.pump();
        expect(
          find.text(nonJsonOutput),
          findsNothing,
          reason:
              "The details of the log haven't computed yet, so they shouldn't "
              'be available.',
        );

        await tester.pumpAndSettle();
        expect(find.text(nonJsonOutput), findsOneWidget);
      });

      testWidgets('can show details of json log data',
          (WidgetTester tester) async {
        const index = 999;
        bool containsJson(Widget widget) {
          if (widget is! Text) return false;
          final text = widget as Text;
          return text.data.contains('{') && text.data.contains('}');
        }

        final findJson = find.descendant(
          of: find.byType(LogDetails),
          matching: find.byWidgetPredicate(containsJson),
        );

        await tester.pumpWidget(wrap(Builder(builder: screen.build)));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(ValueKey(fakeLogData[index])));
        await tester.pump();

        expect(
          findJson,
          findsNothing,
          reason:
              "The details of the log haven't computed yet, so they shouldn't be available.",
        );

        await tester.pumpAndSettle();
        expect(findJson, findsOneWidget);
      });
    });
  });
}

const totalLogs = 1000;
final fakeLogData = List<LogData>.generate(totalLogs, _generate);

LogData _generate(int i) {
  String details = 'log event $i';
  String computedDetails;
  switch (i) {
    case 999:
      computedDetails = jsonOutput;
      break;
    case 998:
      computedDetails = nonJsonOutput;
      break;
    case 997:
      details = null;
      break;
    default:
      break;
  }
  final detailsComputer = computedDetails == null
      ? null
      : () => Future.delayed(const Duration(seconds: 1), () => computedDetails);
  return LogData('kind $i', details, i, detailsComputer: detailsComputer);
}

const nonJsonOutput = 'Non-json details for log number 998';
const jsonOutput = '{\n"Details": "of log event 999",\n"logEvent": "999"\n}\n';
