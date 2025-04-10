// Flutter web plugin registrant file.
//
// Generated file. Do not edit.
//

// @dart = 2.13
// ignore_for_file: type=lint

import 'package:permission_handler_html/permission_handler_html.dart';
import 'package:sweph/sweph.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

void registerPlugins([final Registrar? pluginRegistrar]) {
  final Registrar registrar = pluginRegistrar ?? webPluginRegistrar;
  WebPermissionHandler.registerWith(registrar);
  Sweph.registerWith(registrar);
  registrar.registerMessageHandler();
}
