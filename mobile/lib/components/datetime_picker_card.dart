import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateTimePickerCard extends StatelessWidget {
  final DateTime selectedDate;
  final TimeOfDay selectedStartTime;
  final TimeOfDay selectedEndTime;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<TimeOfDay> onStartTimeChanged;
  final ValueChanged<TimeOfDay> onEndTimeChanged;
  final String? errorText;

  const DateTimePickerCard({
    Key? key,
    required this.selectedDate,
    required this.selectedStartTime,
    required this.selectedEndTime,
    required this.onDateChanged,
    required this.onStartTimeChanged,
    required this.onEndTimeChanged,
    this.errorText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isDark ? Colors.grey[800]! : Colors.blue[50]!,
            isDark ? Colors.grey[850]! : Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: errorText != null
              ? Colors.red.withOpacity(0.5)
              : isDark
                  ? Colors.grey[700]!
                  : Colors.grey[200]!,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.grey[200]!,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showDateTimePicker(context),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.schedule,
                        color: theme.primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Thời gian',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Nhấn để chọn ngày và giờ',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.textTheme.bodySmall?.color
                                  ?.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Date Display
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[700] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: theme.textTheme.bodyMedium?.color
                                ?.withOpacity(0.7),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatDate(selectedDate),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Time Display
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: theme.primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${selectedStartTime.format(context)} - ${selectedEndTime.format(context)}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_getDurationMinutes()} phút',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),

                if (errorText != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 16,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        errorText!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    final yesterday = now.subtract(const Duration(days: 1));

    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Hôm nay';
    } else if (date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day) {
      return 'Ngày mai';
    } else if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return 'Hôm qua';
    } else {
      return DateFormat('EEE, dd/MM/yyyy', 'vi').format(date);
    }
  }

  int _getDurationMinutes() {
    final start =
        DateTime(2023, 1, 1, selectedStartTime.hour, selectedStartTime.minute);
    final end =
        DateTime(2023, 1, 1, selectedEndTime.hour, selectedEndTime.minute);
    return end.difference(start).inMinutes;
  }

  Future<void> _showDateTimePicker(BuildContext context) async {
    // Step 1: Pick Date
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Theme.of(context).primaryColor,
                ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      onDateChanged(pickedDate);

      // Step 2: Pick Start Time
      final TimeOfDay? pickedStartTime = await showTimePicker(
        context: context,
        initialTime: selectedStartTime,
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                    primary: Theme.of(context).primaryColor,
                  ),
            ),
            child: child!,
          );
        },
      );

      if (pickedStartTime != null) {
        onStartTimeChanged(pickedStartTime);

        // Step 3: Pick End Time (with smart default)
        final smartEndTime = TimeOfDay(
          hour: (pickedStartTime.hour + 1) % 24,
          minute: pickedStartTime.minute,
        );

        final TimeOfDay? pickedEndTime = await showTimePicker(
          context: context,
          initialTime: smartEndTime,
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: Theme.of(context).colorScheme.copyWith(
                      primary: Theme.of(context).primaryColor,
                    ),
              ),
              child: child!,
            );
          },
        );

        if (pickedEndTime != null) {
          onEndTimeChanged(pickedEndTime);
        }
      }
    }
  }
}
