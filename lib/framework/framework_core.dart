import 'dart:async';
import 'dart:html' hide Screen;
import 'package:devtools/globals.dart';
import 'package:devtools/service.dart';
import 'package:devtools/service_manager.dart';
import 'package:devtools/vm_service_wrapper.dart';

class FrameworkCore {
  static void init() {
    _setServiceConnectionManager();
    _initVmService();
  }

  static void _setServiceConnectionManager() {
    setGlobal(ServiceConnectionManager, new ServiceConnectionManager());
  }

  static void _initVmService() async {
    // Identify port so that we can connect the VmService.
    int port;
    if (window.location.search.isNotEmpty) {
      final Uri uri = Uri.parse(window.location.toString());
      final String portStr = uri.queryParameters['port'];
      if (portStr != null) {
        port = int.tryParse(portStr);
      }
    }
    port ??= 8100;

    final Completer<Null> finishedCompleter = new Completer<Null>();

    try {
      final VmServiceWrapper service =
          await connect('localhost', port, finishedCompleter);
      if (serviceManager != null) {
        await serviceManager.vmServiceOpened(service, finishedCompleter.future);
      }
    } catch (e) {
      print('Unable to connect to service on port $port');
    }
  }
}
