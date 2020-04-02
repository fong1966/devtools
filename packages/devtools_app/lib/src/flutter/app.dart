// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pedantic/pedantic.dart';

import '../../devtools.dart' as devtools;
import '../../src/framework/framework_core.dart';
import '../debugger/flutter/debugger_screen.dart';
import '../info/flutter/info_screen.dart';
import '../inspector/flutter/inspector_screen.dart';
import '../logging/flutter/logging_screen.dart';
import '../memory/flutter/memory_screen.dart';
import '../network/flutter/network_screen.dart';
import '../performance/flutter/performance_screen.dart';
import '../timeline/flutter/timeline_screen.dart';
import '../ui/flutter/service_extension_widgets.dart';
import 'common_widgets.dart';
import 'connect_screen.dart';
import 'initializer.dart';
import 'notifications.dart';
import 'preferences.dart';
import 'scaffold.dart';
import 'theme.dart';
import 'utils.dart';

// TODO(bkonyi): remove this bool when page is ready.
const showNetworkPage = false;

// TODO(https://github.com/flutter/flutter/issues/43783): Put back
// the debugger screen.
const showDebuggerPage = false;

/// Top-level configuration for the app.
@immutable
class DevToolsApp extends StatefulWidget {
  @override
  State<DevToolsApp> createState() => DevToolsAppState();

  static DevToolsAppState of(BuildContext context) {
    return context.findAncestorStateOfType<DevToolsAppState>();
  }
}

/// Initializer for the [FrameworkCore] and the app's navigation.
///
/// This manages the route generation, and marshalls URL query parameters into
/// flutter route parameters.
// TODO(https://github.com/flutter/devtools/issues/1146): Introduce tests that
// navigate the full app.
class DevToolsAppState extends State<DevToolsApp> {
  final PreferencesController preferences = PreferencesController();

  /// Generates routes, separating the path from URL query parameters.
  Route _generateRoute(RouteSettings settings) {
    final uri = Uri.parse(settings.name);
    final path = uri.path;

    // Provide the appropriate page route.
    if (_routes.containsKey(path)) {
      WidgetBuilder builder =
          (context) => _routes[path](context, uri.queryParameters);

      assert(() {
        builder = (context) {
          return _AlternateCheckedModeBanner(
            builder: (context) => _routes[path](context, uri.queryParameters),
          );
        };
        return true;
      }());

      return MaterialPageRoute(settings: settings, builder: builder);
    }

    // Return a page not found.
    return MaterialPageRoute(
      settings: settings,
      builder: (BuildContext context) {
        return DevToolsScaffold.withChild(
          child: CenteredMessage('Sorry, $uri was not found.'),
        );
      },
    );
  }

  /// The routes that the app exposes.
  final Map<String, UrlParametersBuilder> _routes = {
    '/': (_, params) => Initializer(
          url: params['uri'],
          builder: (_) => DevToolsScaffold(
            tabs: const [
              InspectorScreen(),
              TimelineScreen(),
              MemoryScreen(),
              PerformanceScreen(),
              if (showDebuggerPage) DebuggerScreen(),
              if (showNetworkPage) NetworkScreen(),
              LoggingScreen(),
              InfoScreen(),
            ],
            actions: [
              HotReloadButton(),
              HotRestartButton(),
              OpenSettingsAction(),
              OpenAboutAction(),
            ],
          ),
        ),
    '/connect': (_, __) =>
        DevToolsScaffold.withChild(child: ConnectScreenBody()),
  };

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: preferences.darkModeTheme,
      builder: (context, value, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: themeFor(isDarkTheme: value),
          builder: (context, child) => Notifications(child: child),
          onGenerateRoute: _generateRoute,
        );
      },
    );
  }
}

/// A [WidgetBuilder] that takes an additional map of URL query parameters.
typedef UrlParametersBuilder = Widget Function(
  BuildContext,
  Map<String, String>,
);

/// Displays the checked mode banner in the bottom end corner instead of the
/// top end corner.
///
/// This avoids issues with widgets in the appbar being hidden by the banner
/// in a web or desktop app.
class _AlternateCheckedModeBanner extends StatelessWidget {
  const _AlternateCheckedModeBanner({Key key, this.builder}) : super(key: key);
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return Banner(
      message: 'DEBUG',
      textDirection: TextDirection.ltr,
      location: BannerLocation.topStart,
      child: Builder(
        builder: builder,
      ),
    );
  }
}

class OpenAboutAction extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ActionButton(
      tooltip: 'About DevTools',
      child: InkWell(
        onTap: () async {
          unawaited(showDialog(
            context: context,
            builder: (context) => DevToolsAboutDialog(),
          ));
        },
        child: Container(
          width: DevToolsScaffold.actionWidgetSize,
          height: DevToolsScaffold.actionWidgetSize,
          alignment: Alignment.center,
          child: Icon(
            Icons.info_outline,
            size: actionsIconSize,
          ),
        ),
      ),
    );
  }
}

class OpenSettingsAction extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ActionButton(
      tooltip: 'Settings',
      child: InkWell(
        onTap: () async {
          unawaited(showDialog(
            context: context,
            builder: (context) => const SettingsDialog(),
          ));
        },
        child: Container(
          width: DevToolsScaffold.actionWidgetSize,
          height: DevToolsScaffold.actionWidgetSize,
          alignment: Alignment.center,
          child: Icon(
            Icons.settings,
            size: actionsIconSize,
          ),
        ),
      ),
    );
  }
}

List<Widget> _header(TextTheme textTheme, String title) {
  return [
    Text(title, style: textTheme.headline6),
    const PaddedDivider(padding: EdgeInsets.only(bottom: denseRowSpacing)),
  ];
}

class DevToolsAboutDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      actions: [
        DialogCloseButton(),
      ],
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ..._header(textTheme, 'About DevTools'),
          _aboutDevTools(context),
          const SizedBox(height: defaultSpacing),
          ..._header(textTheme, 'Feedback'),
          Wrap(
            children: [
              const Text('Encountered an issue? Let us know at '),
              _createFeedbackLink(context, textTheme),
              const Text('.')
            ],
          ),
        ],
      ),
    );
  }

  Widget _aboutDevTools(BuildContext context) {
    return const SelectableText('DevTools version ${devtools.version}');
  }

  Widget _createFeedbackLink(BuildContext context, TextTheme textTheme) {
    const urlPath = 'github.com/flutter/devtools/issues';

    return InkWell(
      onTap: () async {
        // TODO(devoncarew): Support analytics.
        // ga.select(ga.devToolsMain, ga.feedback);

        const reportIssuesUrl = 'https://$urlPath';
        await launchUrl(reportIssuesUrl, context);
      },
      child: Text(
        urlPath,
        style: textTheme.bodyText2.copyWith(
          decoration: TextDecoration.underline,
          color: devtoolsLink,
        ),
      ),
    );
  }
}

// TODO(devoncarew): Add an analytics setting.

class SettingsDialog extends StatelessWidget {
  const SettingsDialog({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final preferences = DevToolsApp.of(context).preferences;

    void _toggleTheme([bool value]) {
      value ??= !preferences.darkModeTheme.value;
      preferences.darkModeTheme.value = value;
    }

    return AlertDialog(
      actions: [
        DialogCloseButton(),
      ],
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ..._header(Theme.of(context).textTheme, 'Settings'),
          InkWell(
            onTap: _toggleTheme,
            child: Row(
              children: <Widget>[
                ValueListenableBuilder(
                  valueListenable: preferences.darkModeTheme,
                  builder: (context, value, _) {
                    return Checkbox(
                      value: value,
                      onChanged: _toggleTheme,
                    );
                  },
                ),
                const Text('Use a dark theme'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
