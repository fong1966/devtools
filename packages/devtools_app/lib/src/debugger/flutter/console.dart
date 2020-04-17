// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../flutter/common_widgets.dart';
import '../../flutter/theme.dart';
import 'common.dart';
import 'debugger_controller.dart';

// TODO(devoncarew): Allow scrolling horizontally as well.

// TODO(devoncarew): Show some small UI indicator when we receive stdout/stderr.

// TODO(devoncarew): Support hyperlinking to stack traces.

/// Display the stdout and stderr output from the process under debug.
class Console extends StatefulWidget {
  const Console({
    Key key,
    this.controller,
  }) : super(key: key);

  final DebuggerController controller;

  @override
  _ConsoleState createState() => _ConsoleState();
}

class _ConsoleState extends State<Console> {
  final scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle =
        theme.textTheme.bodyText2.copyWith(fontFamily: 'RobotoMono');

    return OutlinedBorder(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          debuggerSectionTitle(theme, text: 'Console'),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(denseSpacing),
              child: SingleChildScrollView(
                controller: scrollController,
                child: ValueListenableBuilder(
                  valueListenable: widget.controller.stdio,
                  builder: (context, value, _) {
                    // If we're at the end already, scroll to expose the new
                    // content.
                    final pos = scrollController.position;
                    if (pos.pixels == pos.maxScrollExtent) {
                      SchedulerBinding.instance.addPostFrameCallback((_) {
                        _scrollToBottom();
                      });
                    }

                    return Text(value, style: textStyle);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _scrollToBottom() async {
    await scrollController.animateTo(
      scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 100),
      curve: Curves.linear,
    );

    // Scroll again if we've received new content in the interim.
    final pos = scrollController.position;
    if (pos.pixels != pos.maxScrollExtent) {
      scrollController.jumpTo(pos.maxScrollExtent);
    }
  }
}
