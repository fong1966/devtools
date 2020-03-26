// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'core/message_bus.dart';
import 'service_manager.dart';
import 'storage.dart';

/// Snapshot mode is an offline mode where DevTools can operate on an imported
/// data file.
bool offlineMode = false;

final Map<Type, dynamic> globals = <Type, dynamic>{};

ServiceConnectionManager get serviceManager {
  return globals[ServiceConnectionManager];
}

MessageBus get messageBus => globals[MessageBus];

Storage get storage => globals[Storage];

void setGlobal(Type clazz, dynamic instance) {
  globals[clazz] = instance;
}
