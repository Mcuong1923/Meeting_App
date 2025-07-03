import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:metting_app/constants.dart';
import 'package:metting_app/screens/meeting_create_screen.dart';

// --- Data Model ---
enum RoomStatus { available, inUse, maintenance }

class Room {
  final String name;
  final String avatarUrl;
  final RoomStatus status;
  final String floor;
  final int capacity;
  final List<String> equipment;
  final List<String> amenities;

  Room({
    required this.name,
    required this.avatarUrl,
    required this.status,
    required this.floor,
    required this.capacity,
    required this.equipment,
    required this.amenities,
  });
}

// --- Main Screen Widget ---
class RoomManagementScreen extends StatefulWidget {
  const RoomManagementScreen({Key? key}) : super(key: key);

  @override
  _RoomManagementScreenState createState() => _RoomManagementScreenState();
}

class _RoomManagementScreenState extends State<RoomManagementScreen> {
  // Mock data based on the provided design
  final List<Room> _rooms = [
    Room(
      name: 'Phòng Họp Alpha',
      avatarUrl:
          'https://images.unsplash.com/photo-1590650516494-0c8e4a4dd67e?q=80&w=2071&auto=format&fit=crop', // Modern bright room
      status: RoomStatus.available,
      floor: 'Tầng 1',
      capacity: 12,
      equipment: ['Projector', 'Whiteboard', 'Video Conference'],
      amenities: ['WiFi', 'Coffee', 'AC'],
    ),
    Room(
      name: 'Phòng Họp Beta',
      avatarUrl:
          'https://images.unsplash.com/photo-1556761175-5973dc0f32e7?q=80&w=1932&auto=format&fit=crop', // Cosy, smaller room
      status: RoomStatus.inUse,
      floor: 'Tầng 2',
      capacity: 8,
      equipment: ['TV Screen', 'Whiteboard'],
      amenities: ['WiFi', 'AC'],
    ),
    Room(
      name: 'Phòng Họp Gamma',
      avatarUrl:
          'https://images.unsplash.com/photo-1521737852577-684897f2018d?q=80&w=2070&auto=format&fit=crop', // Large corporate room
      status: RoomStatus.maintenance,
      floor: 'Tầng 3',
      capacity: 20,
      equipment: ['Projector', 'Sound System'],
      amenities: ['WiFi', 'Water', 'AC'],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kScaffoldBackgroundColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildSearchBox(),
            const SizedBox(height: 20),
            _buildStatusLegend(),
            const SizedBox(height: 20),
            ..._rooms.map((room) => Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: RoomCard(
                    room: room,
                    onViewDetails: () =>
                        _showRoomDetailsBottomSheet(context, room),
                    onBookRoom: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const MeetingCreateScreen(), // Can pass room info here
                        ),
                      );
                    },
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBox() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Tìm kiếm phòng họp...',
        prefixIcon: const Icon(Icons.search, color: kPrimaryColor),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 15.0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: const BorderSide(color: kPrimaryColor),
        ),
      ),
    );
  }

  Widget _buildStatusLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildLegendItem('Có Sẵn', Colors.green),
        _buildLegendItem('Đang Sử Dụng', Colors.red),
        _buildLegendItem('Bảo Trì', Colors.orange),
      ],
    );
  }

  Widget _buildLegendItem(String text, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}

// --- Room Card Widget ---
class RoomCard extends StatelessWidget {
  final Room room;
  final VoidCallback onViewDetails;
  final VoidCallback onBookRoom;

  const RoomCard({
    Key? key,
    required this.room,
    required this.onViewDetails,
    required this.onBookRoom,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: CachedNetworkImage(
                  imageUrl: room.avatarUrl,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _RoomInfoChip(
                        icon: Icons.location_on_outlined, text: room.floor),
                  ],
                ),
              ),
              _StatusChip(status: room.status),
            ],
          ),
          const SizedBox(height: 16),
          _RoomInfoChip(
              icon: Icons.people_outline,
              text: 'Sức chứa: ${room.capacity} người'),
          const Divider(height: 32),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed:
                      room.status == RoomStatus.available ? onBookRoom : null,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: kPrimaryColor,
                    disabledBackgroundColor: Colors.grey,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Đặt Phòng'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton(
                  onPressed: onViewDetails,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Xem Chi Tiết',
                      style: TextStyle(color: Colors.black54)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- Helper Widgets ---

class _RoomInfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _RoomInfoChip({Key? key, required this.icon, required this.text})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 16),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(color: Colors.grey.shade700)),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final RoomStatus status;
  const _StatusChip({Key? key, required this.status}) : super(key: key);

  String get _text {
    switch (status) {
      case RoomStatus.available:
        return 'Có Sẵn';
      case RoomStatus.inUse:
        return 'Đang Sử Dụng';
      case RoomStatus.maintenance:
        return 'Bảo Trì';
    }
  }

  Color get _color {
    switch (status) {
      case RoomStatus.available:
        return Colors.green;
      case RoomStatus.inUse:
        return Colors.red;
      case RoomStatus.maintenance:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(_text,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold)),
      backgroundColor: _color,
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
    );
  }
}

// --- Bottom Sheet Function ---
void _showRoomDetailsBottomSheet(BuildContext context, Room room) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.8,
        expand: false,
        builder: (_, scrollController) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: ListView(
              controller: scrollController,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  room.name,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '${room.floor} - Sức chứa: ${room.capacity} người',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
                const Divider(height: 40),
                _buildDetailSection('Thiết Bị', room.equipment, Icons.computer),
                const SizedBox(height: 24),
                _buildDetailSection(
                    'Tiện ích', room.amenities, Icons.coffee_maker_outlined),
                const SizedBox(height: 30),
                if (room.status == RoomStatus.available)
                  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12))),
                        onPressed: () {
                          Navigator.pop(context); // Close bottom sheet
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const MeetingCreateScreen(), // Can pass room info here
                            ),
                          );
                        },
                        child: const Text('Đặt Phòng Này',
                            style:
                                TextStyle(fontSize: 16, color: Colors.white)),
                      )),
              ],
            ),
          );
        },
      );
    },
  );
}

Widget _buildDetailSection(String title, List<String> items, IconData icon) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(icon, color: kPrimaryColor, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 12.0,
        runSpacing: 12.0,
        children: items
            .map((item) => Chip(
                  label: Text(item),
                  backgroundColor: Colors.grey.shade100,
                  side: BorderSide(color: Colors.grey.shade200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ))
            .toList(),
      ),
    ],
  );
}
