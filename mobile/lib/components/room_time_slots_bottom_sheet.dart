import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RoomTimeSlotsBottomSheet extends StatefulWidget {
  final String roomId;
  final String roomName;
  final DateTime selectedDate;
  final DateTime currentStart;
  final DateTime currentEnd;
  final Future<List<Map<String, dynamic>>> Function(String, DateTime, DateTime) fetchSchedule;

  const RoomTimeSlotsBottomSheet({
    Key? key,
    required this.roomId,
    required this.roomName,
    required this.selectedDate,
    required this.currentStart,
    required this.currentEnd,
    required this.fetchSchedule,
  }) : super(key: key);

  @override
  State<RoomTimeSlotsBottomSheet> createState() => _RoomTimeSlotsBottomSheetState();
}

class _RoomTimeSlotsBottomSheetState extends State<RoomTimeSlotsBottomSheet> {
  // Config slots: chia khoảng mỗi 30 phút bắt đầu từ 07:00
  final int _startHour = 7;
  final int _endHour = 19;
  final int _intervalMinutes = 30;

  bool _isLoading = true;
  List<Map<String, dynamic>> _scheduleBlocks = [];
  
  final List<DateTime> _allSlots = [];
  DateTime? _selectedSlotStart;
  int _selectedDurationMinutes = 60; // Mặc định chọn 60 phút

  @override
  void initState() {
    super.initState();
    _generateSlots();
    _loadData();
    
    print('[TIMELINE LOG] Opened RoomTimeSlots for Room: ${widget.roomId}, Date: ${widget.selectedDate}');
  }

  void _generateSlots() {
    _allSlots.clear();
    DateTime slotTime = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
      _startHour,
      0,
    );
    DateTime endDay = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
      _endHour,
      0,
    );

    while (slotTime.isBefore(endDay)) {
      _allSlots.add(slotTime);
      slotTime = slotTime.add(Duration(minutes: _intervalMinutes));
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    DateTime startOfDay = DateTime(widget.selectedDate.year, widget.selectedDate.month, widget.selectedDate.day);
    DateTime endOfDay = startOfDay.add(const Duration(days: 1));
    
    _scheduleBlocks = await widget.fetchSchedule(widget.roomId, startOfDay, endOfDay);
    
    print('[TIMELINE LOG] Loaded ${_scheduleBlocks.length} blocks for Room ${widget.roomId}');

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  bool _isSlotUnavailable(DateTime slotStart, DateTime slotEnd) {
    for (var block in _scheduleBlocks) {
      DateTime blockStart = block['start'];
      DateTime blockEnd = block['end'];
      
      // Rule overlap: slStart < blEnd && slEnd > blStart
      if (slotStart.isBefore(blockEnd) && slotEnd.isAfter(blockStart)) {
        return true;
      }
    }
    return false;
  }

  void _onSlotSelected(DateTime slot) {
    DateTime endSlot = slot.add(Duration(minutes: _selectedDurationMinutes));
    
    // Check if the whole duration is available
    if (_isSlotUnavailable(slot, endSlot)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Khung giờ này bị vướng với lịch đã đặt!')),
      );
      return;
    }

    setState(() {
      _selectedSlotStart = slot;
    });
  }

  void _confirmSelection() {
    if (_selectedSlotStart != null) {
      DateTime end = _selectedSlotStart!.add(Duration(minutes: _selectedDurationMinutes));
      
      print('[TIMELINE LOG] Confirmed selection: start=$_selectedSlotStart, end=$end, roomId=${widget.roomId}');
      
      Navigator.pop(context, {
        'start': _selectedSlotStart,
        'end': end,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 0),
      // SafeArea để button không bị che bởi thanh điều hướng dưới cùng
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Chọn khung giờ',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Phòng: ${widget.roomName} - ${DateFormat('dd/MM/yyyy').format(widget.selectedDate)}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Duration Picker
            Row(
              children: [
                const Text('Thời lượng: ', style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(width: 8),
                _buildDurationChip(30),
                const SizedBox(width: 8),
                _buildDurationChip(60),
                const SizedBox(width: 8),
                _buildDurationChip(90),
              ],
            ),
            const SizedBox(height: 16),
            
            // Timeline Content
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _scheduleBlocks.isEmpty && _allSlots.isEmpty
                  ? Center(child: Text('Không có dữ liệu, phòng trống cả ngày', style: TextStyle(color: Colors.grey[600])))
                  : ListView(
                      children: [
                        // List booked blocks mapping visual
                        if (_scheduleBlocks.isNotEmpty) ...[
                          const Text('Lịch đã đặt trong ngày:', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          ..._scheduleBlocks.map((b) {
                            String startTime = DateFormat('HH:mm').format(b['start']);
                            String endTime = DateFormat('HH:mm').format(b['end']);
                            bool isPending = b['status'] == 'pending';
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isPending ? Colors.orange[50] : Colors.red[50],
                                border: Border.all(color: isPending ? Colors.orange[200]! : Colors.red[200]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.schedule, size: 16, color: isPending ? Colors.orange[800] : Colors.red[800]),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '$startTime - $endTime: ${b['title']}',
                                      style: TextStyle(color: isPending ? Colors.orange[900] : Colors.red[900]),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isPending ? Colors.orange : Colors.red,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      isPending ? 'Chờ duyệt' : 'Đã đặt',
                                      style: const TextStyle(color: Colors.white, fontSize: 10),
                                    ),
                                  )
                                ],
                              ),
                            );
                          }).toList(),
                          const Divider(),
                          const SizedBox(height: 8),
                        ],

                        // Actionable slots
                        const Text('Chọn giờ bắt đầu:', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _allSlots.map((slot) {
                            DateTime slotEnd = slot.add(Duration(minutes: _selectedDurationMinutes));
                            bool isUnavailable = _isSlotUnavailable(slot, slotEnd);
                            bool isSelected = _selectedSlotStart == slot;
                            
                            return InkWell(
                              onTap: isUnavailable ? null : () => _onSlotSelected(slot),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFF2C5F6F) : (isUnavailable ? Colors.grey[200] : Colors.white),
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFF2C5F6F) : (isUnavailable ? Colors.grey[300]! : Colors.grey[400]!),
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  DateFormat('HH:mm').format(slot),
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : (isUnavailable ? Colors.grey[500] : Colors.black87),
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    decoration: isUnavailable ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
            ),
            
            // Footer Action
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2C5F6F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  disabledBackgroundColor: Colors.grey[300],
                ),
                onPressed: _selectedSlotStart == null ? null : _confirmSelection,
                child: const Text('Xác nhận khung giờ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationChip(int duration) {
    bool isSelected = _selectedDurationMinutes == duration;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedDurationMinutes = duration;
          _selectedSlotStart = null; // reset selection logic
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2C5F6F).withOpacity(0.1) : Colors.transparent,
          border: Border.all(color: isSelected ? const Color(0xFF2C5F6F) : Colors.grey[400]!),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          '$duration phút',
          style: TextStyle(
            color: isSelected ? const Color(0xFF2C5F6F) : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
