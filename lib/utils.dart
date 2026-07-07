import 'models.dart';

const int defaultMaxRentalHours = 4;
const int bookingClosingHour = 23;
const double defaultHourlyRate = 250;
const List<int> bookingStartHours = [
  6,
  7,
  8,
  9,
  10,
  11,
  12,
  13,
  14,
  15,
  16,
  17,
  18,
  19,
  20,
  21,
  22,
];

DateTime get manilaNow => DateTime.now().toUtc().add(const Duration(hours: 8));

String currency(double value) {
  final fixed = value.toStringAsFixed(2);
  final parts = fixed.split('.');
  final digits = parts.first;
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    final remaining = digits.length - i;
    buffer.write(digits[i]);
    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write(',');
    }
  }
  return '₱${buffer.toString()}.${parts.last}';
}

String formatDate(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

String formatDateLong(DateTime date) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

String formatTime(String time) {
  final parts = time.split(':').map((part) => int.tryParse(part) ?? 0).toList();
  final hour = parts.isNotEmpty ? parts.first : 0;
  final minute = parts.length > 1 ? parts[1] : 0;
  final period = hour >= 12 ? 'PM' : 'AM';
  final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
  return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
}

String formatDateTime(DateTime dateTime) {
  return '${formatDateLong(dateTime)} ${formatTime('${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}')}';
}

String timeForHour(int hour) => '${hour.toString().padLeft(2, '0')}:00:00';

String endTimeFor(String startTime, int durationHours) {
  final hour = int.tryParse(startTime.split(':').first) ?? 0;
  return '${(hour + durationHours).toString().padLeft(2, '0')}:00:00';
}

String durationText(Duration duration) {
  final isNegative = duration.isNegative;
  final safe = isNegative ? Duration.zero : duration;
  final hours = safe.inHours;
  final minutes = safe.inMinutes.remainder(60);
  final seconds = safe.inSeconds.remainder(60);
  if (hours > 0) {
    return '${hours}h ${minutes.toString().padLeft(2, '0')}m ${seconds.toString().padLeft(2, '0')}s';
  }
  return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
}

String statusLabel(Enum status) {
  final words = status.name.split('_');
  return words
      .map(
        (word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');
}

int compareBookings(Booking a, Booking b) {
  final dateCompare = b.localStart.compareTo(a.localStart);
  if (dateCompare != 0) return dateCompare;
  return a.bookingReference.compareTo(b.bookingReference);
}

bool isSameDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

DateTime weekStart(DateTime date) {
  final local = DateTime(date.year, date.month, date.day);
  return local.subtract(Duration(days: local.weekday - 1));
}

String initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'APZ';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
      .toUpperCase();
}

String bookingTimeRange(Booking booking) {
  return '${formatTime(booking.startTime)} - ${formatTime(booking.endTime)}';
}
