String formatDateTime([DateTime? date]) {
  final n = date ?? DateTime.now();
  final o = n.timeZoneOffset;
  final s = o.isNegative ? '-' : '+';
  return "${n.day.toString().padLeft(2, '0')}/"
      "${n.month.toString().padLeft(2, '0')}/"
      "${n.year} "
      "${n.hour.toString().padLeft(2, '0')}:"
      "${n.minute.toString().padLeft(2, '0')} "
      "GMT $s${o.inHours.abs()}:"
      "${(o.inMinutes.abs() % 60).toString().padLeft(2, '0')}";
}
