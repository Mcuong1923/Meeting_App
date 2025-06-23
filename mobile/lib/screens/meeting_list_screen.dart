import 'package:flutter/material.dart';
import 'meeting_create_screen.dart';

class MeetingListScreen extends StatefulWidget {
  const MeetingListScreen({Key? key}) : super(key: key);

  @override
  State<MeetingListScreen> createState() => _MeetingListScreenState();
}

class _MeetingListScreenState extends State<MeetingListScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showList = true;
  List<Map<String, String>> meetings = [
    {
      'title': 'Họp Tổng Kết GpA 2324',
      'time': '4/12/2024',
      'sender': 'Nguyen Quoc Hung',
      'lastMsg': '',
    },
    {
      'title': 'Họp lớp đầu năm K15 CNTT',
      'time': '29/11/2024',
      'sender': 'Nguyen Quoc Hung',
      'lastMsg': '',
    },
    {
      'title': 'Quản trị dự án CNTT - Nhóm 1',
      'time': '2/10/2024',
      'sender': 'Phung The Khai',
      'lastMsg': '',
    },
    {
      'title': 'Tiếng Anh 2-1-1-24(N01)',
      'time': '15/9/2024',
      'sender': 'Nguyen Thanh Huong',
      'lastMsg': '',
    },
    {
      'title': 'Tiếng Anh 2-1-1-24(N01)',
      'time': '12/9/2024',
      'sender': 'Hà Giang',
      'lastMsg': 'em chào cô ạ',
    },
    {
      'title': 'Sinh hoạt công dân giữa kỳ',
      'time': '21/3/2024',
      'sender': 'Phong',
      'lastMsg': '',
    },
    {
      'title': 'Live 3 - CNXH',
      'time': '1/2/2024',
      'sender': 'Nguyen Van Tu',
      'lastMsg': '',
    },
  ];
  String _searchText = '';

  @override
  Widget build(BuildContext context) {
    List<Map<String, String>> filteredMeetings = meetings
        .where((meeting) =>
            meeting['title']!.toLowerCase().contains(_searchText.toLowerCase()))
        .toList();
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6FA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey[200],
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchText = value;
                  });
                },
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _showList = !_showList;
                  });
                },
                child: Row(
                  children: [
                    Icon(
                      _showList
                          ? Icons.keyboard_arrow_down
                          : Icons.keyboard_arrow_right,
                      size: 28,
                      color: Colors.black,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Cuộc họp',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: _showList
                  ? (filteredMeetings.isEmpty
                      ? Center(
                          child: Text(
                            'Không tìm thấy cuộc họp nào.',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 16),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.only(top: 8, bottom: 80),
                          itemCount: filteredMeetings.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 0),
                          itemBuilder: (context, index) {
                            final meeting = filteredMeetings[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.deepPurple[300],
                                radius: 28,
                                child: const Icon(Icons.calendar_month,
                                    color: Colors.white, size: 28),
                              ),
                              title: Text(
                                meeting['title'] ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.black,
                                ),
                              ),
                              subtitle: Text(
                                (meeting['sender'] ?? '') +
                                    (meeting['lastMsg'] != null &&
                                            meeting['lastMsg']!.isNotEmpty
                                        ? ': ${meeting['lastMsg']}'
                                        : ''),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 15, color: Colors.black54),
                              ),
                              trailing: Text(
                                meeting['time'] ?? '',
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black45,
                                    fontWeight: FontWeight.w500),
                              ),
                              onTap: () {
                                // TODO: Xem chi tiết hoặc vào phòng họp
                              },
                            );
                          },
                        ))
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Tạo cuộc họp mới
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const MeetingCreateScreen()),
          );
        },
        backgroundColor: Colors.deepPurple,
        // icon: const Icon(Icons.edit, color: Colors.white),
        icon: const Icon(Icons.edit_note, color: Colors.white),
        label: const Text('Cuộc họp mới',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
