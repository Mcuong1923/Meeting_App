import 'package:flutter/material.dart';

class MeetingMinutesEditorScreen extends StatelessWidget {
  final String minutesId;

  const MeetingMinutesEditorScreen({
    Key? key,
    required this.minutesId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Biên bản cuộc họp'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: const Center(
        child: Text('Meeting Minutes Editor - Coming Soon'),
      ),
    );
  }
}
