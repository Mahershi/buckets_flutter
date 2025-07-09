// logger.dart
import 'package:logging/logging.dart';

void setupLogging(Level level) {
  Logger.root.level = level; // Adjust this depending on the logging level you want.

  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.level.name}: ${rec.loggerName}: ${rec.message}');
    if (rec.error != null) {
      print('  ERROR: ${rec.error}');
    }
    if (rec.stackTrace != null) {
      print('  STACKTRACE: ${rec.stackTrace}');
    }
  });
}