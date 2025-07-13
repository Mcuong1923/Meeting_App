import 'package:flutter/material.dart';

class MeetingMinutesApprovalScreen extends StatelessWidget {
  final String minutesId;

  const MeetingMinutesApprovalScreen({
    Key? key,
    required this.minutesId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Duyệt biên bản'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: const Center(
        child: Text('Meeting Minutes Approval - Coming Soon'),
      ),
    );
  }
}
