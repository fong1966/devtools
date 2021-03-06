// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:html' hide Point;

/// Finds the first descendant element of this document with the given id.
Element queryId(String id) => querySelector('#$id');

/// Finds the first descendant element of this document with the given id.
Element $(String id) => querySelector('#$id');

CoreElement button({String text, String c, String a}) =>
    new CoreElement('button', text: text, classes: c, attributes: a);

CoreElement div({String text, String c, String a}) =>
    new CoreElement('div', text: text, classes: c, attributes: a);

CoreElement span({String text, String c, String a}) =>
    new CoreElement('span', text: text, classes: c, attributes: a);

CoreElement h2({String text, String c, String a}) =>
    new CoreElement('h2', text: text, classes: c, attributes: a);

CoreElement p({String text, String c, String a}) =>
    new CoreElement('p', text: text, classes: c, attributes: a);

CoreElement italic({String text, String c, String a}) =>
    new CoreElement('i', text: text, classes: c, attributes: a);

CoreElement em({String text, String c, String a}) =>
    new CoreElement('em', text: text, classes: c, attributes: a);

CoreElement img({String text, String c, String a}) =>
    new CoreElement('img', text: text, classes: c, attributes: a);

CoreElement ol({String text, String c, String a}) =>
    new CoreElement('ol', text: text, classes: c, attributes: a);

CoreElement ul({String text, String c, String a}) =>
    new CoreElement('ul', text: text, classes: c, attributes: a);

CoreElement li({String text, String c, String a}) =>
    new CoreElement('li', text: text, classes: c, attributes: a);

CoreElement para({String text, String c, String a}) =>
    new CoreElement('p', text: text, classes: c, attributes: a);

CoreElement table() => new CoreElement('table');

CoreElement tr() => new CoreElement('tr');

CoreElement th({String text, String c}) =>
    new CoreElement('th', text: text, classes: c);

CoreElement td({String text, String c}) =>
    new CoreElement('td', text: text, classes: c);

CoreElement form() => new CoreElement('form');

class CoreElement {
  CoreElement(String tag, {String text, String classes, String attributes})
      : element = new Element.tag(tag) {
    if (text != null) {
      element.text = text;
    }
    if (classes != null) {
      element.classes.addAll(classes.split(' '));
    }
    if (attributes != null) {
      attributes.split(' ').forEach(attribute);
    }
  }

  CoreElement.from(this.element);

  final Element element;

  String get tag => element.tagName;

  String get id => attributes['id'];

  set id(String value) => setAttribute('id', value);

  String get src => attributes['src'];

  set src(String value) => setAttribute('src', value);

  bool hasAttribute(String name) => element.attributes.containsKey(name);

  void attribute(String name, [bool value]) {
    value ??= !element.attributes.containsKey(name);

    if (value) {
      element.setAttribute(name, '');
    } else {
      element.attributes.remove(name);
    }
  }

  void toggleAttribute(String name, [bool value]) => attribute(name, value);

  Map<String, String> get attributes => element.attributes;

  void setAttribute(String name, [String value = '']) =>
      element.setAttribute(name, value);

  String clearAttribute(String name) => element.attributes.remove(name);

  void icon(String iconName) =>
      element.classes.addAll(<String>['icon', 'icon-$iconName']);

  void clazz(String _class, {bool removeOthers = false}) {
    if (_class.contains(' ')) {
      throw new ArgumentError('spaces not allowed in class names');
    }
    if (removeOthers) {
      element.classes.clear();
    }
    element.classes.add(_class);
  }

  void toggleClass(String name, [bool value]) {
    element.classes.toggle(name, value);
  }

  String get text => element.text;

  set text(String value) {
    element.text = value;
  }

  /// Add the given child to this element's list of children. [child] must be
  /// either a `CoreElement` or an `Element`.
  dynamic add(dynamic child) {
    if (child is Iterable) {
      return child.map<dynamic>((dynamic c) => add(c)).toList();
    } else if (child is CoreElement) {
      element.children.add(child.element);
    } else if (child is Element) {
      element.children.add(child);
    } else {
      throw new ArgumentError('argument type not supported');
    }
    return child;
  }

  bool get isHidden => hasAttribute('hidden');

  void hidden([bool value]) => attribute('hidden', value);

  String get label => attributes['label'];

  set label(String value) => setAttribute('label', value);

  bool get disabled => hasAttribute('disabled');

  set disabled(bool value) => attribute('disabled', value);

  bool get enabled => !disabled;

  set enabled(bool value) => attribute('disabled', !value);

  // Layout types.
  void layout() => attribute('layout');

  void horizontal() => attribute('horizontal');

  void vertical() => attribute('vertical');

  void layoutHorizontal() {
    setAttribute('layout');
    setAttribute('horizontal');
  }

  void layoutVertical() {
    setAttribute('layout');
    setAttribute('vertical');
  }

  // Layout params.
  void fit() => attribute('fit');

  void flex([int flexAmount]) {
    attribute('flex', true);

    if (flexAmount != null) {
      if (flexAmount == 1)
        attribute('one', true);
      else if (flexAmount == 2)
        attribute('two', true);
      else if (flexAmount == 3)
        attribute('three', true);
      else if (flexAmount == 4)
        attribute('four', true);
      else if (flexAmount == 5) {
        attribute('five', true);
      }
    }
  }

  String get tooltip => element.title;

  set tooltip(String value) {
    element.title = value;
  }

  String get display => element.style.display;

  set display(String value) {
    element.style.display = value;
  }

  int get scrollHeight => element.scrollHeight;

  int get scrollTop => element.scrollTop;

  set scrollTop(int value) => element.scrollTop = value;

  int get offsetHeight => element.offsetHeight;

  String get height => element.style.height;

  set height(String value) {
    element.style.height = value;
  }

  Stream<MouseEvent> get onClick => element.onClick.where((_) => !disabled);

  Stream<Event> get onScroll => element.onScroll;

  Stream<KeyboardEvent> get onKeyDown => element.onKeyDown;

  /// Subscribe to the [onClick] event stream with a no-arg handler.
  StreamSubscription<Event> click(void handle(), [void shiftHandle()]) {
    return onClick.listen((MouseEvent e) {
      e.stopImmediatePropagation();
      if (shiftHandle != null && e.shiftKey) {
        shiftHandle();
      } else {
        handle();
      }
    });
  }

  /// Subscribe to the [onDoubleClick] event stream with a no-arg handler.
  StreamSubscription<Event> dblclick(void handle()) {
    return element.onDoubleClick.listen((Event event) {
      event.stopImmediatePropagation();
      handle();
    });
  }

  void clear() => element.children.clear();

  void scrollIntoView({bool bottom = false}) {
    if (bottom) {
      element.scrollIntoView(ScrollAlignment.BOTTOM);
    } else {
      element.scrollIntoView();
    }
  }

  void setInnerHtml(String str) {
    element.setInnerHtml(str, treeSanitizer: const TrustedHtmlTreeSanitizer());
  }

  // /// Listen for a user copy event (ctrl-c / cmd-c) and copy the selected DOM
  // /// bits into the user's paste buffer.
  // void listenForUserCopy() {
  //   element.onKeyDown.listen(_handleCopyKeyPress);
  // }

  // void _handleCopyKeyPress(KeyboardEvent event) {
  //   // ctrl-c or cmd-c
  //   if (event.keyCode != 67) return;

  //   if ((isMac && event.metaKey) || (!isMac && event.ctrlKey)) {
  //     event.preventDefault();
  //     document.execCommand('copy', false, null);
  //   }
  // }

  void dispose() {
    if (element.parent == null) {
      return;
    }

    if (element.parent.children.contains(element)) {
      try {
        element.parent.children.remove(element);
      } catch (e) {
        // ignore
      }
    }
  }

  @override
  String toString() => element.toString();
}

class CloseButton extends CoreElement {
  CloseButton() : super('div', classes: 'close-button');
}

class TrustedHtmlTreeSanitizer implements NodeTreeSanitizer {
  const TrustedHtmlTreeSanitizer();

  @override
  void sanitizeTree(Node node) {}
}

abstract class CoreElementOwner {
  CoreElement get element;
}

// TODO(dantup): Remove this (plus HasCoreElement above) when we methods on
// CoreElement to handle add/remove from DOM.
abstract class OnAddedToDomMixin implements CoreElementOwner {
  bool isInDom = false;
  MutationObserver observer;
  final StreamController<void> _addedToDomController =
      new StreamController<void>.broadcast();

  Stream<void> get onAddedToDom {
    // Set up an observer that can detect when this element is added to the DOM.
    // TODO(dantup): Can mixins have anything like constructors?
    if (observer == null) {
      observer = new MutationObserver(
          (List<dynamic> mutations, MutationObserver observer) {
        if (document.body.contains(element.element) && !isInDom) {
          isInDom = true;
          _addedToDomController.add(null);
        } else if (!document.body.contains(element.element) && isInDom) {
          isInDom = false;
        }
      });

      // Enable/disable the observer based on whether anyone is listening.
      _addedToDomController.onListen =
          () => observer.observe(document.body, childList: true, subtree: true);
      _addedToDomController.onCancel = () => observer.disconnect();
    }

    return _addedToDomController.stream;
  }
}
