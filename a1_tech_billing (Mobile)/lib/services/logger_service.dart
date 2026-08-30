import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warning, error }

class AppLogger {
  static const String _prefix = '[A1FlowSyn]';

  static void log(
    String message, {
    LogLevel level = LogLevel.info,
    String? tag,
    StackTrace? stackTrace,
  }) {
    if (!kDebugMode) return;

    final tagStr = tag != null ? '[$tag]' : '';
    final levelStr = _getLevelString(level);
    final timestamp = DateTime.now().toIso8601String().split('T').last.split('.').first;
    final logMessage = '$_prefix $levelStr $timestamp $tagStr $message';

    debugPrint(logMessage);

    if (stackTrace != null) {
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  static void debug(String message, {String? tag}) {
    log(message, level: LogLevel.debug, tag: tag);
  }

  static void info(String message, {String? tag}) {
    log(message, level: LogLevel.info, tag: tag);
  }

  static void warning(String message, {String? tag}) {
    log(message, level: LogLevel.warning, tag: tag);
  }

  static void error(
    String message, {
    String? tag,
    StackTrace? stackTrace,
  }) {
    log(message, level: LogLevel.error, tag: tag, stackTrace: stackTrace);
  }

  static String _getLevelString(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '🐛 DEBUG';
      case LogLevel.info:
        return 'ℹ️  INFO';
      case LogLevel.warning:
        return '⚠️  WARN';
      case LogLevel.error:
        return '❌ ERROR';
    }
  }
}
