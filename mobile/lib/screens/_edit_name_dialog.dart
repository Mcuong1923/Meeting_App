import 'package:flutter/material.dart';

/// Simple dialog to edit display name.
///
/// Tách riêng để tránh phụ thuộc MediaQuery chéo overlay và dễ tái sử dụng.
///
/// LƯU Ý:
/// - Không đặt tên class bắt đầu bằng `_` nếu muốn dùng từ file khác,
///   vì trong Dart, các identifier bắt đầu bằng `_` là private theo library.
class EditNameDialog extends StatefulWidget {
  final String initial;

  const EditNameDialog({Key? key, required this.initial}) : super(key: key);

  @override
  State<EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends State<EditNameDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Đổi tên hiển thị'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Tên hiển thị',
          hintText: 'Nhập tên mới',
        ),
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Lưu'),
        ),
      ],
    );
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    Navigator.of(context).pop(value);
  }
}

