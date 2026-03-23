String? parseTimeReference(String message) {
  final lowercaseMsg = message.toLowerCase();

  if (lowercaseMsg.contains('today')) return 'today';
  if (lowercaseMsg.contains('yesterday')) return 'yesterday';
  if (lowercaseMsg.contains('this week')) return 'this_week';
  if (lowercaseMsg.contains('last week')) return 'last_week';
  if (lowercaseMsg.contains('this month')) return 'this_month';
  if (lowercaseMsg.contains('last month')) return 'last_month';
  if (lowercaseMsg.contains('now') || lowercaseMsg.contains('currently')) return 'now';

  return null;
}
