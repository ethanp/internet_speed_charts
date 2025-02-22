import 'package:intl/intl.dart';

class TimeHelpers {
  static final mdy = DateFormat('MM/dd/yy').format;
  static final hms = DateFormat('h:mm:ssa').format;
  static final mdyHms = DateFormat('MM/dd/yy h:mm:ssa').format;
}
