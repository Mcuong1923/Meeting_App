import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> seedDummyData() async {
  final firestore = FirebaseFirestore.instance;
  final meetingId = 'test-meeting-001';

  // 1. Meeting Minutes
  await firestore.collection('meeting_minutes').add({
    'meetingId': meetingId,
    'content': 'Đây là bản ghi cuộc họp mẫu. Nội dung chi tiết bản ghi...',
    'createdBy': 'user123',
    'createdByName': 'Nguyễn Văn A',
    'createdAt': DateTime.now(),
  });

  // 2. Files
  await firestore.collection('files').add({
    'meetingId': meetingId,
    'originalName': 'TaiLieuMau.pdf',
    'downloadUrl':
        'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
    'uploaderId': 'user123',
    'uploaderName': 'Nguyễn Văn A',
    'size': 123456,
    'createdAt': DateTime.now(),
  });

  // 3. Analytics Events
  await firestore.collection('analytics_events').add({
    'targetId': meetingId,
    'type': 'create',
    'userId': 'user123',
    'userName': 'Nguyễn Văn A',
    'timestamp': DateTime.now(),
  });

  print('Đã seed xong data giả!');
}
