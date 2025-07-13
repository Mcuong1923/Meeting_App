import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../components/rounded_input_field.dart';

class MeetingAdvancedForm extends StatelessWidget {
  final TextEditingController agendaController;
  final TextEditingController notesController;
  final bool isRecurring;
  final String? recurringPattern;
  final DateTime? recurringEndDate;
  final bool allowJoinBeforeHost;
  final bool muteOnEntry;
  final bool recordMeeting;
  final List<String> actionItems;
  final ValueChanged<bool> onRecurringChanged;
  final ValueChanged<String?> onRecurringPatternChanged;
  final ValueChanged<DateTime?> onRecurringEndDateChanged;
  final ValueChanged<bool> onAllowJoinBeforeHostChanged;
  final ValueChanged<bool> onMuteOnEntryChanged;
  final ValueChanged<bool> onRecordMeetingChanged;
  final ValueChanged<List<String>> onActionItemsChanged;

  const MeetingAdvancedForm({
    Key? key,
    required this.agendaController,
    required this.notesController,
    required this.isRecurring,
    required this.recurringPattern,
    required this.recurringEndDate,
    required this.allowJoinBeforeHost,
    required this.muteOnEntry,
    required this.recordMeeting,
    required this.actionItems,
    required this.onRecurringChanged,
    required this.onRecurringPatternChanged,
    required this.onRecurringEndDateChanged,
    required this.onAllowJoinBeforeHostChanged,
    required this.onMuteOnEntryChanged,
    required this.onRecordMeetingChanged,
    required this.onActionItemsChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cài đặt nâng cao',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Agenda
        RoundedInputField(
          hintText: "Chương trình họp",
          controller: agendaController,
          maxLines: 3,
        ),
        const SizedBox(height: 16),

        // Notes
        RoundedInputField(
          hintText: "Ghi chú",
          controller: notesController,
          maxLines: 3,
        ),
        const SizedBox(height: 16),

        // Recurring Meeting
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cuộc họp định kỳ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  title: const Text('Lặp lại cuộc họp'),
                  value: isRecurring,
                  onChanged: (value) {
                    onRecurringChanged(value ?? false);
                  },
                ),
                if (isRecurring) ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: recurringPattern,
                    decoration: const InputDecoration(
                      labelText: 'Tần suất lặp lại',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'daily',
                        child: Text('Hàng ngày'),
                      ),
                      DropdownMenuItem(
                        value: 'weekly',
                        child: Text('Hàng tuần'),
                      ),
                      DropdownMenuItem(
                        value: 'monthly',
                        child: Text('Hàng tháng'),
                      ),
                    ],
                    onChanged: onRecurringPatternChanged,
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () => _selectRecurringEndDate(context),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Ngày kết thúc lặp lại',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        recurringEndDate != null
                            ? DateFormat('dd/MM/yyyy').format(recurringEndDate!)
                            : 'Chọn ngày kết thúc',
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Meeting Settings
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cài đặt cuộc họp',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  title: const Text('Cho phép tham gia trước chủ trì'),
                  value: allowJoinBeforeHost,
                  onChanged: (value) {
                    onAllowJoinBeforeHostChanged(value ?? false);
                  },
                ),
                CheckboxListTile(
                  title: const Text('Tắt tiếng khi vào'),
                  value: muteOnEntry,
                  onChanged: (value) {
                    onMuteOnEntryChanged(value ?? false);
                  },
                ),
                CheckboxListTile(
                  title: const Text('Ghi âm cuộc họp'),
                  value: recordMeeting,
                  onChanged: (value) {
                    onRecordMeetingChanged(value ?? false);
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Action Items
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Công việc cần làm',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...actionItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: item,
                            decoration: InputDecoration(
                              labelText: 'Công việc ${index + 1}',
                              border: const OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              final newItems = List<String>.from(actionItems);
                              newItems[index] = value;
                              onActionItemsChanged(newItems);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.remove_circle),
                          onPressed: () {
                            final newItems = List<String>.from(actionItems);
                            newItems.removeAt(index);
                            onActionItemsChanged(newItems);
                          },
                        ),
                      ],
                    ),
                  );
                }).toList(),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    final newItems = List<String>.from(actionItems);
                    newItems.add('');
                    onActionItemsChanged(newItems);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm công việc'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectRecurringEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          recurringEndDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      onRecurringEndDateChanged(picked);
    }
  }
}
