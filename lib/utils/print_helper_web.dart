import 'dart:html' as html;
import 'print_models.dart';

Future<void> printScheduleImpl(List<PrintMonthData> months) async {
  final buffer = StringBuffer();
  buffer.writeln('<!doctype html>');
  buffer.writeln('<html lang="ja">');
  buffer.writeln('<head>');
  buffer.writeln('<meta charset="utf-8">');
  buffer.writeln('<meta name="viewport" content="width=device-width, initial-scale=1">');
  buffer.writeln('<title>イベントスケジュール</title>');
  buffer.writeln('<style>');
  buffer.writeln('body { font-family: "Noto Sans JP", "Hiragino Kaku Gothic ProN", "Yu Gothic", sans-serif; margin: 24px; color: #111; }');
  buffer.writeln('.wrapper { display: flex; gap: 24px; align-items: flex-start; flex-wrap: nowrap; }');
  buffer.writeln('.month { flex: 1; min-width: 0; }');
  buffer.writeln('.month-title { font-size: 20px; font-weight: 700; margin: 0 0 12px; }');
  buffer.writeln('.day-row { display: flex; border-bottom: 1px solid #ddd; padding: 0; align-items: flex-start; }');
  buffer.writeln('.day-row.has-events { padding: 0; }');
  buffer.writeln('.day-row.closed { background: #f0f0f0; }');
  buffer.writeln('.cell-date { width: 56px; font-weight: 700; align-self: center; line-height: 1.0; display: flex; gap: 0; }');
  buffer.writeln('.cell-date .date-part { display: inline-block; width: 2ch; text-align: right; }');
  buffer.writeln('.cell-date .weekday-part { margin-left: 0; }');
  buffer.writeln('.cell-events { flex: 1; font-size: 10px; line-height: 0.9; white-space: pre-wrap; padding: 0; }');
  buffer.writeln('.day-row.has-events { background: #f7f0ad; }');
  buffer.writeln('.event-title { font-weight: 600; margin: 0; padding: 0; line-height: 1.0; white-space: nowrap; display: block; overflow: hidden; }');
  buffer.writeln('.event-time { font-size: 7px; font-weight: 500; margin-left: 4px; white-space: nowrap; }');
  buffer.writeln('.event-time.block { display: block; margin-left: 0; }');
  buffer.writeln('.weekday-sun { color: #c62828; }');
  buffer.writeln('.weekday-sat { color: #1e40af; }');
  buffer.writeln('@media print {');
  buffer.writeln('  body { margin: 10mm; }');
  buffer.writeln('  .wrapper { gap: 16px; }');
  buffer.writeln('  .day-row { page-break-inside: avoid; }');
  buffer.writeln('}');
  buffer.writeln('</style>');
  buffer.writeln('</head>');
  buffer.writeln('<body>');
  buffer.writeln('<div class="wrapper">');
  for (final month in months) {
    buffer.writeln('<section class="month">');
    buffer.writeln('<h2 class="month-title">${_escape(month.monthLabel)}</h2>');
    for (final day in month.days) {
      final hasEvents = day.events.isNotEmpty;
      final rowClass = [
        'day-row',
        if (day.isClosedDay) 'closed',
        if (hasEvents && !day.isClosedDay) 'has-events',
      ].join(' ');
      final weekdayClass = day.weekdayLabel == '日'
          ? 'weekday-sun'
          : day.weekdayLabel == '土'
              ? 'weekday-sat'
              : '';
      buffer.writeln('<div class="$rowClass">');
      buffer.writeln('<div class="cell-date $weekdayClass"><span class="date-part">${_escape(_padDayLabel(day.dayLabel))}</span><span class="weekday-part">${_escape(day.weekdayLabel)}</span></div>');
      final eventsClass = 'cell-events';
      buffer.writeln('<div class="$eventsClass">');
      if (day.events.isEmpty) {
        buffer.writeln('　');
      } else {
        for (var i = 0; i < day.events.length; i++) {
          final event = day.events[i];
          if (event.timeLabel.trim().isEmpty) {
            buffer.writeln('<div class="event-title">${_escape(event.title)}</div>');
          } else {
            final shouldBreak = event.title.trim().length >= 12;
            final timeClass = shouldBreak ? 'event-time block' : 'event-time';
            buffer.writeln('<div class="event-title">${_escape(event.title)}<span class="$timeClass">${_escape(event.timeLabel)}</span></div>');
          }
          if (i != day.events.length - 1) {
            buffer.writeln('<div style="height:0;"></div>');
          }
        }
      }
      buffer.writeln('</div>');
      buffer.writeln('</div>');
    }
    buffer.writeln('</section>');
  }
  buffer.writeln('</div>');
  buffer.writeln('<script>');
  buffer.writeln('function fitTitles(){');
  buffer.writeln('  var titles=document.querySelectorAll(".event-title");');
  buffer.writeln('  titles.forEach(function(el){');
  buffer.writeln('    el.style.whiteSpace="nowrap";');
  buffer.writeln('    el.style.display="block";');
  buffer.writeln('    el.style.overflow="hidden";');
  buffer.writeln('    var size=10; var min=7;');
  buffer.writeln('    var computed=parseFloat(window.getComputedStyle(el).fontSize || "10");');
  buffer.writeln('    if(!isNaN(computed)){size=computed;}');
  buffer.writeln('    el.style.fontSize=size+"px";');
  buffer.writeln('    while(el.scrollWidth>el.clientWidth && size>min){size-=1; el.style.fontSize=size+"px";}');
  buffer.writeln('  });');
  buffer.writeln('}');
  buffer.writeln('window.onload=function(){');
  buffer.writeln('  requestAnimationFrame(function(){');
  buffer.writeln('    fitTitles();');
  buffer.writeln('    setTimeout(function(){window.print();}, 50);');
  buffer.writeln('  });');
  buffer.writeln('};');
  buffer.writeln('</script>');
  buffer.writeln('</body>');
  buffer.writeln('</html>');

  final blob = html.Blob([buffer.toString()], 'text/html');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.window.open(url, '_blank');
  html.Url.revokeObjectUrl(url);

}

String _escape(String input) {
  return input
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;');
}

String _padDayLabel(String label) {
  if (label.length == 1) {
    return ' $label';
  }
  return label;
}
