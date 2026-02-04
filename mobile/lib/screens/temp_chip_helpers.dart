
  Widget _buildStatusChip(String status, {bool isSelected = false}) {
    Color bg;
    Color fg;
    String label;
    IconData icon;

    switch (status) {
      case 'pending':
        bg = const Color(0xFFFFF3E0); // Orange 50
        fg = const Color(0xFFFF9800); // Orange 500
        label = 'Chưa bắt đầu';
        icon = Icons.hourglass_empty_rounded;
        break;
      case 'in_progress':
        bg = const Color(0xFFE3F2FD); // Blue 50
        fg = const Color(0xFF2196F3); // Blue 500
        label = 'Đang thực hiện';
        icon = Icons.autorenew_rounded;
        break;
      case 'completed':
        bg = const Color(0xFFE8F5E9); // Green 50
        fg = const Color(0xFF4CAF50); // Green 500
        label = 'Hoàn thành';
        icon = Icons.check_circle_outline_rounded;
        break;
      default:
        bg = Colors.grey.shade100;
        fg = Colors.grey;
        label = 'Không xác định';
        icon = Icons.help_outline;
    }

    if (isSelected) {
       // When selected and displayed in the button, we might want a cleaner look or same look
       // Let's use the colored pill look
       return Container(
         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
         decoration: BoxDecoration(
           color: bg,
           borderRadius: BorderRadius.circular(8),
         ),
         child: Row(
           mainAxisSize: MainAxisSize.min,
           children: [
             Icon(icon, size: 16, color: fg),
             const SizedBox(width: 8),
             Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 13)),
           ],
         ),
       );
    }
    
    // In dropdown list
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Icon(icon, size: 14, color: fg),
        ),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
      ],
    );
  }

  Widget _buildPriorityChip(String priority, {bool isSelected = false}) {
     Color bg;
    Color fg;
    String label;
    IconData icon;

    switch (priority) {
      case 'high':
        bg = const Color(0xFFFFEBEE); // Red 50
        fg = const Color(0xFFF44336); // Red 500
        label = 'Ưu tiên Cao';
        icon = Icons.priority_high_rounded;
        break;
      case 'medium':
        bg = const Color(0xFFFFF3E0); // Orange 50
        fg = const Color(0xFFFF9800); // Orange 500
        label = 'Ưu tiên TB';
        icon = Icons.remove;
        break;
      case 'low':
        bg = const Color(0xFFE8F5E9); // Green 50
        fg = const Color(0xFF4CAF50); // Green 500
        label = 'Ưu tiên Thấp';
        icon = Icons.arrow_downward_rounded;
        break;
      default:
        bg = Colors.grey.shade100;
        fg = Colors.grey;
        label = 'TB';
        icon = Icons.remove;
    }

    if (isSelected) {
       return Container(
         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
         decoration: BoxDecoration(
           color: bg,
           borderRadius: BorderRadius.circular(8),
         ),
         child: Row(
           mainAxisSize: MainAxisSize.min,
           children: [
             Icon(icon, size: 16, color: fg),
             const SizedBox(width: 8),
             Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 13)),
           ],
         ),
       );
    }

    return Row(
      children: [
         Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Icon(icon, size: 14, color: fg),
        ),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
      ],
    );
  }
