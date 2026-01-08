import 'print_helper_stub.dart'
    if (dart.library.html) 'print_helper_web.dart';
import 'print_models.dart';

export 'print_models.dart';

Future<void> printSchedule(List<PrintMonthData> months) =>
    printScheduleImpl(months);
