import 'package:flutter/material.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import 'window_manager_helper_default.dart';

class MacOsImpl {
  static const _keyPosDisplay = 'DESKTOP_WINDOW_POS_DISPLAY';

  static Future<void> setBounds(SharedPreferences prefs, Rect bounds) async {
    await windowManager.setMinimumSize(const Size(minimumWidth, 0));

    final width = bounds.width;
    final height = bounds.height;
    final posX = bounds.left;
    final posY = bounds.top;

    final posDisplay = prefs.getString(_keyPosDisplay);

    if (posDisplay != null) {
      final displays = await screenRetriever.getAllDisplays();
      for (var d in displays) {
        if (d.name == posDisplay) {
          var globalPos =
              Offset(10 + d.visiblePosition!.dx, 10 + d.visiblePosition!.dy);
          if ((posX >= 0) &&
              (posX < d.visibleSize!.width) &&
              (posY >= 0) &&
              (posY < d.visibleSize!.height)) {
            // if the local position exists on the display, use it
            globalPos = Offset(
                posX + d.visiblePosition!.dx, posY + d.visiblePosition!.dy);
          }

          await windowManager.setBounds(null,
              size: Size(width, height),
              position: Offset(globalPos.dx, globalPos.dy));
        }
      }
    }
  }

  static Future<Rect> getBounds(SharedPreferences prefs) async {
    final size = await windowManager.getSize();
    final offset = await windowManager.getPosition();
    final displays = await screenRetriever.getAllDisplays();

    for (var d in displays) {
      if (d.visiblePosition != null &&
          d.visibleSize != null &&
          d.name != null) {
        final windowCenter =
            Offset(offset.dx + size.width / 2.0, offset.dy + size.height / 2.0);
        if ((windowCenter.dx >= d.visiblePosition!.dx) &&
            (windowCenter.dx <
                (d.visiblePosition!.dx + d.visibleSize!.width)) &&
            (windowCenter.dy >= d.visiblePosition!.dy) &&
            (windowCenter.dy <
                (d.visiblePosition!.dy + d.visibleSize!.height))) {
          final localOffset = Offset(offset.dx - d.visiblePosition!.dx,
              offset.dy - d.visiblePosition!.dy);
          await prefs.setString(_keyPosDisplay, d.name!);

          return Rect.fromLTWH(
              localOffset.dx, localOffset.dy, size.width, size.height);
        }
      }
    }

    return defaultWindowBounds; // default
  }
}
