#!/bin/bash

# Copyright 2018 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Fast fail the script on failures.
set -e

# Print out the Dart version in use.
# dart --version

# Get Flutter.
curl https://storage.googleapis.com/flutter_infra/releases/stable/macos/flutter_macos_v1.0.0-stable.zip -o flutter.zip
unzip flutter.zip
./flutter/bin/flutter config --no-analytics
./flutter/bin/flutter doctor
export FLUTTER_SDK=`pwd`/flutter

# Echo build info.
echo $FLUTTER_SDK
./flutter/bin/flutter --version

# Add globally activated packages to the path.
export PATH="$PATH":./flutter/bin:./flutter/bin/cache/dart-sdk/bin:~/.pub-cache/bin

# Analyze the source.
./flutter/bin/cache/dart-sdk/bin/pub global activate tuneup
tuneup check --ignore-infos

# Ensure we can build the app.
./flutter/bin/cache/dart-sdk/bin/pub global activate webdev
webdev build

# Run the tests.
./flutter/bin/cache/dart-sdk/bin/pub run test
./flutter/bin/cache/dart-sdk/bin/pub run test -pchrome-no-sandbox
