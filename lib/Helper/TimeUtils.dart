class TimeUtils {
  static int getMinutesFromMatchTime(String time) {
    try {
      if (time.isEmpty) return 0;
      final parts = time.toLowerCase().split(' ');
      int minutes = 0;

      for (int i = 0; i < parts.length; i += 2) {
        if (i + 1 >= parts.length) break;
        final value = int.tryParse(parts[i].replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        final unit = parts[i + 1].trim();

        if (unit.startsWith('d')) {
          minutes += value * 24 * 60;
        } else if (unit.startsWith('h')) {
          minutes += value * 60;
        } else if (unit.startsWith('m')) {
          minutes += value;
        }
      }
      return minutes;
    } catch (e) {
      print('Error parsing match time: $time');
      return 0;
    }
  }
}