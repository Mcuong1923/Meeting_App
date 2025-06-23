import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:metting_app/constants.dart';

class MeetingCreateScreen extends StatefulWidget {
  const MeetingCreateScreen({Key? key}) : super(key: key);

  @override
  State<MeetingCreateScreen> createState() => _MeetingCreateScreenState();
}

class _MeetingCreateScreenState extends State<MeetingCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _otherLocCtrl = TextEditingController();
  final _inviteCtrl = TextEditingController();

  DateTime? _start, _end;
  String? _room;
  String _type = 'Offline';
  String _priority = 'Trung bình';
  bool _private = false;

  final _rooms = [
    '-- Chọn phòng họp --',
    'Phòng 101',
    'Phòng 202',
    'Phòng 305',
  ];

  /* ---------------- Helper ---------------- */
  Future<void> _pickDateTime(bool isStart) async {
    final init = isStart ? DateTime.now() : (_start ?? DateTime.now());
    final d = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
    );
    if (d == null) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(init),
    );
    if (t == null) return;
    final dt = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    setState(() => isStart ? _start = dt : _end = dt);
  }

  String _fmt(DateTime? dt) => dt == null
      ? 'dd/mm/yyyy --:-- --'
      : DateFormat('dd/MM/yyyy – HH:mm').format(dt);

  InputDecoration _dec(String? label, {String? hint}) => InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDADADA)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDADADA)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF673AB7)),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      );

  /* ---------------- UI ---------------- */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundPink,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Tạo cuộc họp mới',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /* Tiêu đề */
                TextFormField(
                  controller: _titleCtrl,
                  decoration: _dec('Tiêu đề *'),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Vui lòng nhập tiêu đề' : null,
                ),
                const SizedBox(height: 16),

                /* Mô tả */
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 3,
                  decoration: _dec('Mô tả'),
                ),
                const SizedBox(height: 16),

                /* Bắt đầu */
                InkWell(
                  onTap: () => _pickDateTime(true),
                  child: InputDecorator(
                    decoration: _dec('Bắt đầu *'),
                    child: Text(_fmt(_start)),
                  ),
                ),
                const SizedBox(height: 16),

                /* Kết thúc */
                InkWell(
                  onTap: () => _pickDateTime(false),
                  child: InputDecorator(
                    decoration: _dec('Kết thúc *'),
                    child: Text(_fmt(_end)),
                  ),
                ),
                const SizedBox(height: 24),

                /* Địa điểm */
                const Text('Địa điểm',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _room ?? _rooms.first,
                  decoration: _dec(null),
                  items: _rooms
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => _room = v),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _otherLocCtrl,
                  decoration: _dec(null, hint: 'Hoặc nhập địa điểm khác'),
                ),
                const SizedBox(height: 24),

                /* Loại cuộc họp */
                DropdownButtonFormField<String>(
                  value: _type,
                  decoration: _dec('Loại cuộc họp'),
                  items: ['Offline', 'Online']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => _type = v ?? 'Offline'),
                ),
                const SizedBox(height: 16),

                /* Mức ưu tiên */
                DropdownButtonFormField<String>(
                  value: _priority,
                  decoration: _dec('Mức ưu tiên'),
                  items: ['Thấp', 'Trung bình', 'Cao']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => _priority = v ?? 'Trung bình'),
                ),
                const SizedBox(height: 16),

                /* Riêng tư */
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: const Color(0xFFDADADA), width: 1),
                  ),
                  child: SwitchListTile(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    value: _private,
                    onChanged: (v) => setState(() => _private = v),
                    title: const Text('Cuộc họp riêng tư'),
                    subtitle: const Text(
                        'Chỉ những người cùng phòng ban mới có thể thấy'),
                  ),
                ),
                const SizedBox(height: 16),

                /* Mời tham gia */
                TextFormField(
                  controller: _inviteCtrl,
                  decoration: _dec('Mời người tham gia',
                      hint: 'Nhập tên, email hoặc phòng ban'),
                ),
                const SizedBox(height: 24),

                /* Nút tạo */
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF673AB7),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      if (!(_formKey.currentState?.validate() ?? false)) return;
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Đã tạo cuộc họp!')));
                      Navigator.pop(context);
                    },
                    child: const Text('Tạo cuộc họp',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
