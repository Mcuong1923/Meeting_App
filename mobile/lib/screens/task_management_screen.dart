import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../models/meeting_model.dart';
import '../models/user_model.dart';
import '../models/meeting_task_model.dart';
import 'task_detail_screen.dart';
import 'package:provider/provider.dart';
import '../providers/meeting_provider.dart';

class TaskManagementScreen extends StatefulWidget {
  final MeetingModel meeting;
  final List<MeetingTask>? initialTasks;

  const TaskManagementScreen({
    Key? key,
    required this.meeting,
    this.initialTasks,
  }) : super(key: key);

  @override
  State<TaskManagementScreen> createState() => _TaskManagementScreenState();
}

class _TaskManagementScreenState extends State<TaskManagementScreen> with SingleTickerProviderStateMixin {
  // late List<MeetingTask> _tasks; // Removed to fix conflict with getter
  String _selectedStatusTab = MeetingTaskStatus.pending; // pending, in_progress, completed
  String _selectedPriority = 'all';
  String _viewMode = 'list';

  @override
  void initState() {
    super.initState();
    print('[TASK_SCREEN][INIT] initializing... meetingId=${widget.meeting.id}');
    // Load tasks from provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('[TASK_SCREEN][POST_FRAME] calling loadTasks...');
      context.read<MeetingProvider>().loadTasks(widget.meeting.id);
    });
  }

  // Helper to access tasks from provider
  List<MeetingTask> get _tasks => context.watch<MeetingProvider>().tasks;

  List<MeetingTask> get _filteredTasks {
    return _tasks.where((task) {
      // Filter by Tab Status
      if (task.status != _selectedStatusTab) {
        return false;
      }
      // Filter by Priority
      if (_selectedPriority != 'all' && task.priority != _selectedPriority) {
        return false;
      }
      return true;
    }).toList();
  }

  int get _totalTasks => _tasks.length;
  int get _overdueTasks => _tasks.where((t) => t.deadline.isBefore(DateTime.now()) && t.status != 'completed').length;
  int get _upcomingTasks => _tasks.where((t) {
    final daysUntil = t.deadline.difference(DateTime.now()).inDays;
    return daysUntil >= 0 && daysUntil <= 3 && t.status != 'completed';
  }).length;
  int get _completedTasks => _tasks.where((t) => t.status == 'completed').length;

  int getCountByStatus(String status) => _tasks.where((t) => t.status == status).length;

  @override
  Widget build(BuildContext context) {
    print('[TASK_SCREEN][BUILD] tasksCount=${_tasks.length}');
    final isLoading = context.watch<MeetingProvider>().isLoading;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            const Text(
              'Quản Lý Công Việc',
              style: TextStyle(
                color: Color(0xFF1A1A1A),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Cuộc họp: ${widget.meeting.title}',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _showCreateTaskDialog,
            icon: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Color(0xFF2196F3),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // 1. KPI Carousel (Fixed Height)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            height: 110, // Fixed height to prevent overflow
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildStatCard('Tổng công việc', _totalTasks.toString(), Icons.assignment, const Color(0xFF2196F3), const Color(0xFFE3F2FD)),
                const SizedBox(width: 12),
                _buildStatCard('Quá hạn', _overdueTasks.toString(), Icons.warning_amber_rounded, const Color(0xFFF44336), const Color(0xFFFFEBEE)),
                const SizedBox(width: 12),
                _buildStatCard('Sắp đến hạn', _upcomingTasks.toString(), Icons.access_time_filled, const Color(0xFFFF9800), const Color(0xFFFFF3E0)),
                const SizedBox(width: 12),
                _buildStatCard('Hoàn thành', _completedTasks.toString(), Icons.check_circle, const Color(0xFF4CAF50), const Color(0xFFE8F5E9)),
                const SizedBox(width: 16),
              ],
            ),
          ),
          
          // 2. Status Segmented Control (Sticky-like)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade100), bottom: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  _buildSegmentTab('Chờ xử lý', MeetingTaskStatus.pending, Colors.orange),
                  _buildSegmentTab('Đang làm', MeetingTaskStatus.inProgress, Colors.blue),
                  _buildSegmentTab('Hoàn thành', MeetingTaskStatus.completed, Colors.green),
                ],
              ),
            ),
          ),

          // 3. Task List (Expanded)
          Expanded(
            child: _buildTaskListView(),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskListView() {
    final tasks = _filteredTasks;
    final isLoading = context.watch<MeetingProvider>().isLoading;

    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const CircularProgressIndicator()
            else ...[
              Icon(Icons.assignment_outlined, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text('Chưa có công việc ở trạng thái này', style: TextStyle(color: Colors.grey.shade500)),
              const SizedBox(height: 8),
              // Debug: Show total raw tasks to prove data existence
              Text('Debug: Total ${_tasks.length} tasks loaded (ignore filter)', style: TextStyle(color: Colors.grey.shade400, fontSize: 10)),
            ],
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      separatorBuilder: (ctx, i) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) => _buildTaskCard(tasks[i]),
    );
  }

  Widget _buildTaskCard(MeetingTask task) {
    final isOverdue = task.deadline.isBefore(DateTime.now()) && task.status != 'completed';
    
    return Slidable(
      key: ValueKey(task.id),
      startActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) => _handleDeleteTask(task),
            backgroundColor: const Color(0xFFFEFEFE),
            foregroundColor: const Color(0xFFF44336),
            icon: Icons.delete_outline,
            label: 'Xóa',
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
          ),
           SlidableAction(
            onPressed: (context) => _handleEditTask(task),
            backgroundColor: const Color(0xFFFEFEFE),
            foregroundColor: const Color(0xFF2196F3),
            icon: Icons.edit_outlined,
            label: 'Sửa',
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) => _handleCompleteTask(task),
            backgroundColor: const Color(0xFFE8F5E9),
            foregroundColor: const Color(0xFF4CAF50),
            icon: Icons.check_circle_outline,
            label: 'Hoàn thành',
            borderRadius: const BorderRadius.only(topRight: Radius.circular(16), bottomRight: Radius.circular(16)),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: () {
          TaskDetailScreen.show(
            context,
            task: task,
            onUpdate: (updatedTask) {
              context.read<MeetingProvider>().updateTask(updatedTask);
            },
            onDelete: (deletedTask) {
              context.read<MeetingProvider>().deleteTask(deletedTask.id).then((success) {
                if (success && mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã xóa công việc')),
                  );
                }
              });
            },
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Title & Badges
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildPriorityBadge(task.priority),
                ],
              ),
              const SizedBox(height: 12),
              
              // Row 2: Avatar & Name
              Row(
                children: [
                  CircleAvatar(
                    radius: 10,
                    backgroundColor: const Color(0xFF9B7FED),
                    child: Text(
                      task.assigneeName.isNotEmpty ? task.assigneeName[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      task.assigneeName,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                      maxLines: 1, 
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildStatusChip(task.status),
                ],
              ),
              const SizedBox(height: 12),
              
              // Row 3: Deadline & Progress
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 14, color: isOverdue ? Colors.red : Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      DateFormat('dd/MM/yyyy').format(task.deadline) + (isOverdue ? ' (Quá hạn)' : ''),
                      style: TextStyle(
                        fontSize: 12, 
                        color: isOverdue ? Colors.red : Colors.grey.shade600,
                        fontWeight: isOverdue ? FontWeight.w600 : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Compact progress
                  Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      Container(
                        width: 60,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      Container(
                        width: 60 * (task.progress / 100),
                        height: 6,
                        decoration: BoxDecoration(
                          color: _getProgressColor(task.progress.toDouble()),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Text('${task.progress.round()}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Handlers ---
  void _handleCompleteTask(MeetingTask task) {
    final updatedTask = task.copyWith(
      status: 'completed',
      progress: 100,
      updatedAt: DateTime.now(),
    );
    
    // Call API logic here via Provider
    context.read<MeetingProvider>().updateTask(updatedTask).then((success) {
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã hoàn thành: ${task.title}'), backgroundColor: Colors.green)
        );
      }
    });
  }

  void _handleDeleteTask(MeetingTask task) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa công việc'),
        content: const Text('Bạn chắc chắn muốn xóa công việc này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<MeetingProvider>().deleteTask(task.id).then((success) {
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã xóa công việc')),
                  );
                }
              });
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _handleEditTask(MeetingTask task) {
    // TODO: Show edit task dialog
  }

  void _showCreateTaskDialog() {
     // TODO: Show create task dialog
  }


  // --- Helper Widgets ---

  Widget _buildSegmentTab(String label, String value, Color activeColor) {
    final isSelected = _selectedStatusTab == value;
    final count = getCountByStatus(value);
    
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedStatusTab = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected ? [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
            ] : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? activeColor : Colors.grey.shade600,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                     color: isSelected ? activeColor.withOpacity(0.1) : Colors.grey.shade300,
                     borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? activeColor : Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, Color bgColor) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(fontSize: 12, color: color.withOpacity(0.8), fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildPriorityBadge(String priority) {
    Color color;
    String label;
    switch(priority) {
      case 'high': color = Colors.orange; label = 'Cao'; break;
      case 'medium': color = Colors.blue; label = 'TB'; break;
      case 'low': color = Colors.green; label = 'Thấp'; break;
      default: color = Colors.grey; label = 'TB';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildStatusChip(String status) {
     // Optional: If we want status in card even if tab filtered
     // But user asked for it in card layout.
    Color color;
    String label;
    switch(status) {
      case 'pending': color = Colors.orange; label = 'Chờ xử lý'; break;
      case 'in_progress': color = Colors.blue; label = 'Đang làm'; break;
      case 'completed': color = Colors.green; label = 'Hoàn thành'; break;
      default: color = Colors.grey; label = 'Unknown';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }

  Color _getProgressColor(double progress) {
    if (progress >= 100) return const Color(0xFF4CAF50);
    if (progress >= 50) return const Color(0xFF2196F3);
    return const Color(0xFFFF9800);
  }
}
