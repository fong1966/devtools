// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart' hide Stack;
import 'package:provider/provider.dart';
import 'package:vm_service/vm_service.dart';

import '../../flutter/theme.dart';
import 'debugger_controller.dart';
import 'debugger_model.dart';

class CallStack extends StatefulWidget {
  const CallStack({Key key}) : super(key: key);

  @override
  _CallStackState createState() => _CallStackState();
}

class _CallStackState extends State<CallStack> {
  DebuggerController controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final newController = Provider.of<DebuggerController>(context);
    if (newController == controller) return;
    controller = newController;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<StackFrameAndSourcePosition>>(
      valueListenable: controller.stackFramesWithLocation,
      builder: (context, stackFrames, _) {
        return ValueListenableBuilder<StackFrameAndSourcePosition>(
          valueListenable: controller.selectedStackFrame,
          builder: (context, selectedFrame, _) {
            return ListView.builder(
              itemCount: stackFrames.length,
              itemExtent: defaultListItemHeight,
              itemBuilder: (_, index) {
                final frame = stackFrames[index];
                return _buildStackFrame(frame, frame == selectedFrame);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildStackFrame(
    StackFrameAndSourcePosition frame,
    bool selected,
  ) {
    final theme = Theme.of(context);

    final regularStyle = TextStyle(color: theme.textTheme.bodyText2.color);
    final subtleStyle = TextStyle(color: theme.unselectedWidgetColor);
    final selectedStyle = TextStyle(color: theme.textSelectionColor);

    Widget child;

    final asyncMarker = frame.frame.kind == FrameKind.kAsyncSuspensionMarker;
    if (asyncMarker) {
      child = Row(
        children: [
          const SizedBox(width: defaultSpacing, child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: densePadding),
            child: Text(
              _descriptionFor(frame),
              style: selected ? selectedStyle : subtleStyle,
            ),
          ),
          const Expanded(child: Divider()),
        ],
      );
    } else {
      child = RichText(
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          text: _descriptionFor(frame),
          style: selected ? selectedStyle : regularStyle,
          children: [
            TextSpan(
              text: _locationFor(frame),
              style: selected ? selectedStyle : subtleStyle,
            ),
          ],
        ),
      );
    }

    return Material(
      color: selected ? theme.selectedRowColor : null,
      child: InkWell(
        onTap: () => _onStackFrameSelected(frame),
        child: Container(
          padding: const EdgeInsets.all(densePadding),
          alignment: Alignment.centerLeft,
          child: child,
        ),
      ),
    );
  }

  Future<void> _onStackFrameSelected(StackFrameAndSourcePosition frame) async {
    controller.selectStackFrame(frame);

    // TODO(kenz): Change the line selection in the code view as well.
    // TODO(kenz): consider un-selecting the selected breakpoint here.
    if (frame.script != null) {
      await controller.selectScript(frame.script);
    } else if (frame.scriptUri != null) {
      await controller
          .selectScript(controller.scriptRefForUri(frame.scriptUri));
    }
  }

  String _descriptionFor(StackFrameAndSourcePosition frame) {
    const unoptimized = '[Unoptimized] ';
    const none = '<none>';
    const anonymousClosure = '<anonymous closure>';
    const closure = '<closure>';
    const asyncBreak = '<async break>';

    if (frame.frame.kind == FrameKind.kAsyncSuspensionMarker) {
      return asyncBreak;
    }

    var name = frame.frame.code?.name ?? none;
    if (name.startsWith(unoptimized)) {
      name = name.substring(unoptimized.length);
    }
    name = name.replaceAll(anonymousClosure, closure);
    name = name == none ? name : '$name()';
    return name;
  }

  String _locationFor(StackFrameAndSourcePosition frame) {
    final uri = frame.scriptUri;
    if (uri == null) {
      return uri;
    }
    final file = uri.split('/').last;
    return ' $file:${frame.line}';
  }
}
