// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:vm_service/vm_service.dart';

import '../../../devtools.dart' as devtools;
import '../../flutter/common_widgets.dart';
import '../../flutter/octicons.dart';
import '../../flutter/screen.dart';
import '../../version.dart';
import '../info_controller.dart';

class InfoScreen extends Screen {
  const InfoScreen()
      : super(
          DevToolsScreenType.info,
          title: 'Info',
          icon: Octicons.info,
        );

  @override
  bool get showIsolateSelector => true;

  @override
  Widget build(BuildContext context) => InfoScreenBody();

  /// The key to identify the flutter version view.
  @visibleForTesting
  static const Key flutterVersionKey = Key('Info Screen Flutter Version');

  /// The key to identify the flag list view
  @visibleForTesting
  static const Key flagListKey = Key('Info Screen Flag List');
}

class InfoScreenBody extends StatefulWidget {
  @override
  _InfoScreenBodyState createState() => _InfoScreenBodyState();
}

class _InfoScreenBodyState extends State<InfoScreenBody> {
  FlutterVersion _flutterVersion;

  InfoController _controller;

  @override
  void initState() {
    super.initState();
    _controller = InfoController(
      onFlutterVersionChanged: (flutterVersion) {
        if (!mounted) return;
        setState(
          () {
            _flutterVersion = flutterVersion;
          },
        );
      },
    )..entering();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Version Information',
          style: textTheme.headline5,
        ),
        const PaddedDivider(padding: EdgeInsets.only(top: 4.0, bottom: 0.0)),
        if (_flutterVersion != null)
          _VersionInformation(_flutterVersion),
        const Padding(padding: EdgeInsets.only(top: 16.0)),
        // TODO(devoncarew): Move this information into an advanced page.
        Text(
          'Dart VM Flag List',
          style: textTheme.headline5,
        ),
        const PaddedDivider(padding: EdgeInsets.only(top: 4.0, bottom: 0.0)),
        Expanded(
          child: ValueListenableBuilder<FlagList>(
            valueListenable: _controller.flagListNotifier,
            builder: (context, flagList, _) {
              if (flagList == null || flagList.flags.isEmpty) {
                return const SizedBox();
              }
              return _FlagList(flagList);
            },
          ),
        ),
      ],
    );
  }
}

class _VersionInformation extends StatelessWidget {
  const _VersionInformation(this.flutterVersion);

  final FlutterVersion flutterVersion;

  @override
  Widget build(BuildContext context) {
    const boldText = TextStyle(fontWeight: FontWeight.bold);

    final versions = {
      'DevTools': devtools.version,
      'Flutter': flutterVersion.version,
      'Framework': flutterVersion.frameworkRevision,
      'Engine': flutterVersion.engineRevision,
      'Dart': flutterVersion.dartSdkVersion,
    };

    return Column(
      key: InfoScreen.flutterVersionKey,
      children: [
        for (var name in versions.keys)
          Padding(
            padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
            child: Row(
              children: [
                Text(name, style: boldText),
                const SizedBox(width: 8.0),
                Text(versions[name]),
              ],
            ),
          ),
      ],
    );
  }
}

class _FlagList extends StatelessWidget {
  const _FlagList(this.flagList);

  final FlagList flagList;

  @override
  Widget build(BuildContext context) {
    final defaultTextTheme = DefaultTextStyle.of(context).style;
    return Scrollbar(
      child: ListView.builder(
        key: InfoScreen.flagListKey,
        itemCount: flagList?.flags?.length ?? 0,
        itemBuilder: (context, index) {
          final flag = flagList.flags[index];
          final modifiedStatusText = flag.modified ? 'modified' : 'default';
          return Padding(
            padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(flag.name, style: semibold(defaultTextTheme)),
                      Text(flag.comment),
                    ],
                  ),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 100.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        flag.valueAsString,
                        textAlign: TextAlign.end,
                        style: primaryColor(defaultTextTheme, context),
                      ),
                      Text(
                        modifiedStatusText,
                        textAlign: TextAlign.end,
                        style: primaryColorLight(defaultTextTheme, context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
