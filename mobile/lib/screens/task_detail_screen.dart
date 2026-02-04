import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/meeting_task_model.dart';
import '../models/user_model.dart';

class TaskDetailScreen extends StatefulWidget {
  final MeetingTask task;
  final Function(MeetingTask) onUpdate;
  final Function(MeetingTask) onDelete;

  const TaskDetailScreen({
    Key? key,
    required this.task,
    required this.onUpdate,
    required this.onDelete,
  }) : super(key: key);

  static void show(
    BuildContext context, {
    required MeetingTask task,
    required Function(MeetingTask) onUpdate,
    required Function(MeetingTask) onDelete,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.95,
        minChildSize: 0.5,
        maxChildSize: 1.0,
        builder: (_, controller) => TaskDetailScreen(
          task: task,
          onUpdate: onUpdate,
          onDelete: onDelete,
        ),
      ),
    );
  }

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late MeetingTask _editedTask;
  // Separate controllers/state for complex edits
  late TextEditingController _descriptionController;
  late TextEditingController _commentController;
  final ScrollController _scrollController = ScrollController();
  
  bool _isDirty = false;
  bool _isSaving = false;
  bool _isEditingDescription = false;
  int _activeTab = 0; // 0: Details, 1: Subtasks, 2: Comments, 3: History

  @override
  void initState() {
    super.initState();
    _editedTask = widget.task;
    _descriptionController = TextEditingController(text: _editedTask.description ?? '');
    _commentController = TextEditingController();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _markDirty() {
    setState(() {
      _isDirty = true;
    });
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    
    try {
      // Simulate API delay
      await Future.delayed(const Duration(milliseconds: 600));

      final updated = _editedTask.copyWith(
         updatedAt: DateTime.now(),
         description: _descriptionController.text,
      );
      
      final historyItem = TaskHistory(
        id: const Uuid().v4(), 
        action: 'Updated', 
        description: 'Updated task details', 
        createdBy: 'You', 
        createdAt: DateTime.now()
      );
      
      final finalTask = updated.copyWith(
        history: [historyItem, ...updated.history],
        status: updated.progress >= 100 ? 'completed' : 
                (updated.progress > 0 ? 'in_progress' : updated.status)
      );

      widget.onUpdate(finalTask);
      
      widget.onUpdate(finalTask);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text('Đã lưu thay đổi', style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            backgroundColor: const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(20),
            duration: const Duration(seconds: 2),
            elevation: 4,
          ),
        );
        Navigator.pop(context); // Return to management screen
      }
    } catch (e, stack) {
      debugPrint('Error saving task: $e\n$stack');
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi lưu: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _cancelChanges() {
     setState(() {
       _editedTask = widget.task;
       _descriptionController.text = _editedTask.description ?? '';
       _isDirty = false;
       _isEditingDescription = false;
     });
  }

  // --- Actions ---

  void _handleDeadlineEdit() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _editedTask.deadline,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (pickedDate != null && pickedDate != _editedTask.deadline) {
      setState(() {
        _editedTask = _editedTask.copyWith(deadline: pickedDate);
      });
      _markDirty();
    }
  }
  
  void _addSubtask() {
    // Show dialog to add subtask
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thêm công việc con'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Nhập nội dung...'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                 final newSubtask = TaskSubtask(
                   id: const Uuid().v4(), 
                   title: controller.text
                 );
                 setState(() {
                   _editedTask = _editedTask.copyWith(
                     subtasks: [..._editedTask.subtasks, newSubtask]
                   );
                 });
                 _markDirty();
              }
              Navigator.pop(ctx);
            }, 
            child: const Text('Thêm')
          ),
        ],
      ),
    );
  }

  void _toggleSubtask(int index) {
    setState(() {
      final subtasks = List<TaskSubtask>.from(_editedTask.subtasks);
      final task = subtasks[index];
      subtasks[index] = task.copyWith(isCompleted: !task.isCompleted);
      _editedTask = _editedTask.copyWith(subtasks: subtasks);
    });
    _markDirty();
  }

  void _deleteSubtask(int index) {
    setState(() {
      final subtasks = List<TaskSubtask>.from(_editedTask.subtasks);
      subtasks.removeAt(index);
      _editedTask = _editedTask.copyWith(subtasks: subtasks);
    });
    _markDirty();
  }

  void _addComment() {
    if (_commentController.text.isEmpty) return;
    
    final newComment = TaskComment(
      id: const Uuid().v4(),
      userId: 'current_user',
      userName: 'Bạn', // Mock
      content: _commentController.text,
      createdAt: DateTime.now(),
    );
    
    // Comments are saved immediately usually, but let's follow the "Manual Save" rule or save separately?
    // User requirement: "Comment gửi save riêng, không phụ thuộc nút Lưu thay đổi"
    
    setState(() {
       // Optimistic update
       _editedTask = _editedTask.copyWith(
         comments: [newComment, ..._editedTask.comments]
       );
       _commentController.clear();
    });
    
    // Simulate API background save
    Future.delayed(const Duration(milliseconds: 500)).then((_) {
       widget.onUpdate(_editedTask); // Sync to parent
    });
  }

  void _showActionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildActionSheet(ctx),
    );
  }

  Widget _buildActionSheet(BuildContext ctx) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            const Text('Thao tác', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.check_circle_outline, color: Colors.green),
              title: const Text('Hoàn thành công việc'),
              onTap: () {
                Navigator.pop(ctx);
                _completeTask();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Xóa công việc', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDelete();
              },
            ),
            const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _completeTask() {
    final task = _editedTask.copyWith(status: 'completed', progress: 100);
    // Complete is a major action, usually immediate save
    widget.onUpdate(task);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã hoàn thành!'), backgroundColor: Colors.green));
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa công việc?'),
        content: const Text('Bạn chắc chắn muốn xóa?'),
        actions: [
           TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
           TextButton(onPressed: () {
             Navigator.pop(ctx);
             Navigator.pop(context); // close detail
             widget.onDelete(widget.task);
           }, child: const Text('Xóa', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  // --- UI Building ---

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF5F7FA),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(),
          
          // Tabs
          _buildTabs(),

          // Content
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                   if (_activeTab == 0) _buildMainDetails(),
                   if (_activeTab == 1) _buildSubtasks(),
                   if (_activeTab == 2) _buildComments(),
                   if (_activeTab == 3) _buildHistory(),
                   const SizedBox(height: 100), // Space for footer
                ],
              ),
            ),
          ),
          
          // Sticky Footer
          if (_isDirty) _buildStickyFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
          ),
          const Expanded(child: Text('Chi tiết công việc', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
          TextButton.icon(
             onPressed: _showActionSheet,
             icon: const Icon(Icons.menu_rounded, size: 20, color: Color(0xFF1A1A1A)),
             label: const Text('Thao tác', style: TextStyle(color: Color(0xFF1A1A1A))),
             style: TextButton.styleFrom(backgroundColor: Colors.grey.shade100, shape: const StadiumBorder()),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            _buildTabItem(0, 'Chi tiết'),
            _buildTabItem(1, 'Việc nhỏ (${_editedTask.subtasks.length})'),
            _buildTabItem(2, 'Trao đổi (${_editedTask.comments.length})'),
            _buildTabItem(3, 'Lịch sử'),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(int index, String label) {
    final isActive = _activeTab == index;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = index),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.black87 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(color: isActive ? Colors.white : Colors.grey.shade700, fontWeight: FontWeight.bold, fontSize: 13)),
      ),
    );
  }

  Widget _buildMainDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(_editedTask.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        
        // Status & Priority Selectors (Refined Design)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0), // Parent already has padding
          child: Row(
            children: [
              // Status Selector
              Expanded(
                child: _buildCustomDropdown<String>(
                  title: 'Trạng thái',
                  value: _editedTask.status,
                  itemBuilder: (context) => [
                    _buildPopupItem('pending', _buildStatusChip('pending')),
                    _buildPopupItem('in_progress', _buildStatusChip('in_progress')),
                    _buildPopupItem('completed', _buildStatusChip('completed')),
                  ],
                  childBuilder: (val) => _buildStatusChip(val, isSelected: true),
                  onSelected: (val) {
                    if (val != _editedTask.status) {
                      setState(() {
                         _editedTask = _editedTask.copyWith(
                           status: val,
                           progress: val == 'completed' ? 100 : (val == 'pending' ? 0 : _editedTask.progress),
                         );
                      });
                      _markDirty();
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              // Priority Selector
              Expanded(
                child: _buildCustomDropdown<String>(
                  title: 'Độ ưu tiên',
                  value: _editedTask.priority,
                  itemBuilder: (context) => [
                    _buildPopupItem('high', _buildPriorityChip('high')),
                    _buildPopupItem('medium', _buildPriorityChip('medium')),
                    _buildPopupItem('low', _buildPriorityChip('low')),
                  ],
                  childBuilder: (val) => _buildPriorityChip(val, isSelected: true),
                  onSelected: (val) {
                    if (val != _editedTask.priority) {
                      setState(() {
                         _editedTask = _editedTask.copyWith(priority: val);
                      });
                      _markDirty();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        // Assignee & Deadline (Editable)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
               Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     const Text('Người thực hiện', style: TextStyle(color: Colors.grey, fontSize: 12)),
                     const SizedBox(height: 4),
                     Row(
                       children: [
                         const CircleAvatar(radius: 12, backgroundColor: Colors.purpleAccent, child: Text('A', style: TextStyle(fontSize: 10, color: Colors.white))),
                         const SizedBox(width: 8),
                         Expanded(child: Text(_editedTask.assigneeName, style: const TextStyle(fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                       ],
                     )
                   ],
                 ),
               ),
               Container(width: 1, height: 40, color: Colors.grey.shade200, margin: const EdgeInsets.symmetric(horizontal: 16)),
               Expanded(
                 child: InkWell(
                   onTap: _handleDeadlineEdit,
                   borderRadius: BorderRadius.circular(8),
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Row(
                         children: const [
                           Text('Hạn hoàn thành', style: TextStyle(color: Colors.grey, fontSize: 12)),
                           SizedBox(width: 4),
                           Icon(Icons.edit, size: 12, color: Colors.blue),
                         ],
                       ),
                       const SizedBox(height: 4),
                       Row(
                         children: [
                           Icon(Icons.calendar_today, size: 16, color: _editedTask.isOverdue ? Colors.red : Colors.black87),
                           const SizedBox(width: 8),
                           Text(
                             DateFormat('dd/MM/yyyy').format(_editedTask.deadline),
                             style: TextStyle(fontWeight: FontWeight.w500, color: _editedTask.isOverdue ? Colors.red : Colors.black87),
                           ),
                         ],
                       )
                     ],
                   ),
                 ),
               ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        // Progress Slider
        const Text('Tiến độ', style: TextStyle(fontWeight: FontWeight.bold)),
        Slider(
          value: _editedTask.progress.toDouble(),
          min: 0, max: 100,
          onChanged: (val) {
             setState(() {
               _editedTask = _editedTask.copyWith(progress: val.round());
             });
             _markDirty();
          },
          label: '${_editedTask.progress}%',
        ),
        Center(child: Text('${_editedTask.progress}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
        
        const SizedBox(height: 24),
        
        // Description (Editable)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Mô tả', style: TextStyle(fontWeight: FontWeight.bold)),
            if (!_isEditingDescription)
              IconButton(onPressed: () => setState(() => _isEditingDescription = true), icon: const Icon(Icons.edit, size: 16, color: Colors.blue))
          ],
        ),
        if (_isEditingDescription)
          TextField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Nhập mô tả...',
            ),
            onChanged: (_) => _markDirty(),
          )
        else
          Container(
             width: double.infinity,
             padding: const EdgeInsets.all(16),
             decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
             child: Text(_editedTask.description ?? 'Chưa có mô tả', style: TextStyle(color: Colors.grey.shade800)),
          ),
      ],
    );
  }

  Widget _buildSubtasks() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Danh sách việc nhỏ (${_editedTask.subtasks.where((e) => e.isCompleted).length}/${_editedTask.subtasks.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
            TextButton.icon(onPressed: _addSubtask, icon: const Icon(Icons.add, size: 16), label: const Text('Thêm')),
          ],
        ),
        if (_editedTask.subtasks.isEmpty)
          const Padding(padding: EdgeInsets.all(32), child: Text('Chưa có việc nhỏ nào', style: TextStyle(color: Colors.grey))),
        ..._editedTask.subtasks.asMap().entries.map((entry) {
           final index = entry.key;
           final item = entry.value;
           return Card(
             margin: const EdgeInsets.only(bottom: 8),
             child: CheckboxListTile(
               value: item.isCompleted,
               title: Text(item.title, style: TextStyle(decoration: item.isCompleted ? TextDecoration.lineThrough : null)),
               onChanged: (_) => _toggleSubtask(index),
               secondary: IconButton(icon: const Icon(Icons.close, size: 16, color: Colors.grey), onPressed: () => _deleteSubtask(index)),
               controlAffinity: ListTileControlAffinity.leading,
             ),
           );
        }).toList(),
      ],
    );
  }

  Widget _buildComments() {
    return Column(
      children: [
         // Input
         Row(
           children: [
             Expanded(
               child: TextField(
                 controller: _commentController,
                 decoration: const InputDecoration(
                   hintText: 'Viết bình luận...',
                   filled: true,
                   fillColor: Colors.white,
                   border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(24))),
                   contentPadding: EdgeInsets.symmetric(horizontal: 16),
                 ),
               ),
             ),
             const SizedBox(width: 8),
             IconButton(onPressed: _addComment, icon: const Icon(Icons.send, color: Colors.blue)),
           ],
         ),
         const SizedBox(height: 20),
         if (_editedTask.comments.isEmpty)
            const Padding(padding: EdgeInsets.all(32), child: Text('Chưa có bình luận nào', style: TextStyle(color: Colors.grey))),
         
         ..._editedTask.comments.map((c) => Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(radius: 10, child: Icon(Icons.person, size: 12)),
                    const SizedBox(width: 8),
                    Text(c.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const Spacer(),
                    Text(DateFormat('HH:mm dd/MM').format(c.createdAt), style: const TextStyle(color: Colors.grey, fontSize: 10)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(c.content),
              ],
            ),
         )).toList(),
      ],
    );
  }
  
  Widget _buildHistory() {
     if (_editedTask.history.isEmpty) {
        return const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('Chưa có lịch sử', style: TextStyle(color: Colors.grey))));
     }
     return Column(
       children: _editedTask.history.map((h) => ListTile(
         leading: const Icon(Icons.history, size: 20, color: Colors.grey),
         title: Text(h.description),
         subtitle: Text('${h.createdBy} • ${DateFormat('HH:mm dd/MM/yyyy').format(h.createdAt)}'),
         dense: true,
       )).toList(),
     );
  }

  Widget _buildStickyFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _cancelChanges,
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: const Text('Hủy thay đổi'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue, 
                padding: const EdgeInsets.symmetric(vertical: 16),
                disabledBackgroundColor: Colors.blue.shade200,
              ),
              child: _isSaving 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                  : const Text('Lưu thay đổi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // --- Helpers ---

  Widget _buildCustomDropdown<T>({
    required String title,
    required T value,
    required List<PopupMenuEntry<T>> Function(BuildContext) itemBuilder,
    required Widget Function(T) childBuilder,
    required Function(T) onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Builder(
          builder: (context) {
            return GestureDetector(
              onTap: () {
                final RenderBox button = context.findRenderObject() as RenderBox;
                final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
                final RelativeRect position = RelativeRect.fromRect(
                  Rect.fromPoints(
                    button.localToGlobal(Offset.zero, ancestor: overlay),
                    button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
                  ),
                  Offset.zero & overlay.size,
                );

                showMenu<T>(
                  context: context,
                  position: position,
                  items: itemBuilder(context),
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  color: Colors.white,
                  constraints: const BoxConstraints(minWidth: 140, maxWidth: 220),
                ).then((newValue) {
                  if (newValue != null) {
                    onSelected(newValue);
                  }
                });
              },
              child: Container(
                height: 44, // Target height 40-44px
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8), // Reduced radius
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
                  ],
                  border: Border.all(color: Colors.grey.shade100),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, // Ensure spread
                  children: [
                    Expanded(child: childBuilder(value)),
                    Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Colors.grey.shade400),
                  ],
                ),
              ),
            );
          }
        ),
      ],
    );
  }

  PopupMenuItem<T> _buildPopupItem<T>(T value, Widget child) {
    return PopupMenuItem<T>(
      value: value,
      height: 40, // Compact height
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: child,
    );
  }

  Widget _buildStatusChip(String status, {bool isSelected = false}) {
    Color bg;
    Color fg;
    String label;
    IconData icon;

    switch (status) {
      case 'pending':
        bg = const Color(0xFFFFF7E6); // Warning light (Orangeish)
        fg = const Color(0xFFFF8D4F); // Warning text
        label = 'Chưa bắt đầu';
        icon = Icons.hourglass_empty_rounded;
        break;
      case 'in_progress':
        bg = const Color(0xFFE6F7FF); // Info light (Blueish)
        fg = const Color(0xFF40A9FF); // Info text
        label = 'Đang thực hiện';
        icon = Icons.autorenew_rounded;
        break;
      case 'completed':
        bg = const Color(0xFFF6FFED); // Success light (Greenish)
        fg = const Color(0xFF73D13D); // Success text
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
       return Row(
         mainAxisSize: MainAxisSize.min,
         children: [
             // For selected state inside button: show icon + text cleanly
             // User requested "Màu chỉ nên ở icon/chip, không làm nền quá đậm để tránh rối."
             // And "Icon + text căn giữa theo chiều dọc"
             Container(
               padding: const EdgeInsets.all(4),
               decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                child: Icon(icon, size: 16, color: fg),
             ),
             const SizedBox(width: 8),
             Flexible(
               child: Text(
                 label, 
                 style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87),
                 overflow: TextOverflow.ellipsis,
               ),
             ),
           ],
       );
    }
    
    // In dropdown list
    return Row(
      children: [
        Icon(icon, size: 18, color: fg),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label, 
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Colors.black87),
            overflow: TextOverflow.ellipsis,
          ),
        ),
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
        // Cao: đỏ/cam nhẹ
        bg = const Color(0xFFFFF1F0); // Red light
        fg = const Color(0xFFFF4D4F); // Red text
        label = 'Cao';
        icon = Icons.priority_high_rounded;
        break;
      case 'medium':
        // TB: xanh dương nhạt (Updated requirement)
        bg = const Color(0xFFE6F7FF); // Blue light
        fg = const Color(0xFF1890FF); // Blue text
        label = 'Trung bình';
        icon = Icons.remove;
        break;
      case 'low':
        // Thấp: xanh lá nhạt
        bg = const Color(0xFFF6FFED); // Green light
        fg = const Color(0xFF52C41A); // Green text
        label = 'Thấp';
        icon = Icons.arrow_downward_rounded;
        break;
      default:
        bg = Colors.grey.shade100;
        fg = Colors.grey;
        label = 'TB';
        icon = Icons.remove;
    }

    if (isSelected) {
       return Row(
         mainAxisSize: MainAxisSize.min,
         children: [
            Container(
               padding: const EdgeInsets.all(4),
               decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                child: Icon(icon, size: 16, color: fg),
             ),
             const SizedBox(width: 8),
             Flexible(
               child: Text(
                 label, 
                 style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87),
                 overflow: TextOverflow.ellipsis,
               ),
             ),
           ],
       );
    }

    return Row(
      children: [
        Icon(icon, size: 18, color: fg),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
             label, 
             style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Colors.black87),
             overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
