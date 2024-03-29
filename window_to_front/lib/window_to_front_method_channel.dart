import 'package:flutter/services.dart';

import 'window_to_front_platform_interface.dart';

/// An implementation of [WindowToFrontPlatform] that uses method channels.
class MethodChannelWindowToFront extends WindowToFrontPlatform {
  /// The method channel used to interact with the native platform.
  final methodChannel = const MethodChannel('window_to_front');

  // Replace the getPlatformVersion() with the following implementation
  @override
  Future<void> activate() async {
    return methodChannel.invokeMethod('activate');
  }
}