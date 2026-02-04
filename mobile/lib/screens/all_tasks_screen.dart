import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/meeting_provider.dart';
import '../models/meeting_task_model.dart';
import 'task_detail_screen.dart';

class AllTasksScreen extends StatefulWidget {
  const AllTasksScreen({Key? key}) : super(key: key);

  @override
  State<AllTasksScreen> createState() => _AllTasksScreenState();
}

class _AllTasksScreenState extends State<AllTasksScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedStatusFilter = 'all'; // all, pending, in_progress, completed

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTasks();
  }

  void _loadTasks() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final meetingProvider = Provider.of<MeetingProvider>(context, listen: false);
    
    if (authProvider.userModel != null) {
      meetingProvider.loadAllUserTasks(authProvider.userModel!.id);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final meetingProvider = Provider.of<MeetingProvider>(context);
    final currentUser = authProvider.userModel;

    if (currentUser == null) return const SizedBox();

    final allTasks = meetingProvider.allTasks;
    
    // Filter tasks
    final myAssignedTasks = allTasks.where((t) => 
      t.assigneeId == currentUser.id &&
      (_selectedStatusFilter == 'all' || t.status == _selectedStatusFilter)
    ).toList();

    final myCreatedTasks = allTasks.where((t) => 
      t.createdBy == currentUser.id &&
      (_selectedStatusFilter == 'all' || t.status == _selectedStatusFilter)
    ).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quản lý công việc',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Color(0xFF1A1A1A),
              ),
            ),
            Text(
              'Theo dõi và cập nhật tiến độ',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF2C1B47),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF2C1B47),
          tabs: [
            Tab(text: 'Được giao (${myAssignedTasks.length})'),
            Tab(text: 'Đã giao (${myCreatedTasks.length})'),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list_rounded, color: Color(0xFF1A1A1A)),
            onSelected: (value) {
              setState(() => _selectedStatusFilter = value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('Tất cả')),
              const PopupMenuItem(value: 'pending', child: Text('Chờ xử lý')),
              const PopupMenuItem(value: 'in_progress', child: Text('Đang thực hiện')),
              const PopupMenuItem(value: 'completed', child: Text('Hoàn thành')),
            ],
          ),
        ],
      ),
      body: meetingProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTaskList(myAssignedTasks, isAssignedToMe: true),
                _buildTaskList(myCreatedTasks, isAssignedToMe: false),
              ],
            ),
    );
  }

  Widget _buildTaskList(List<MeetingTask> tasks, {required bool isAssignedToMe}) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assignment_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Không có công việc nào',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        return _buildTaskCard(tasks[index], isAssignedToMe);
      },
    );
  }

  Widget _buildTaskCard(MeetingTask task, bool isAssignedToMe) {
    Color statusColor;
    String statusText;

    switch (task.status) {
      case MeetingTaskStatus.pending:
        statusColor = Colors.orange;
        statusText = 'Chờ xử lý';
        break;
      case MeetingTaskStatus.inProgress:
        statusColor = Colors.blue;
        statusText = 'Đang thực hiện';
        break;
      case MeetingTaskStatus.completed:
        statusColor = Colors.green;
        statusText = 'Hoàn thành';
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Không xác định';
    }

    final isOverdue = task.deadline.isBefore(DateTime.now()) && 
                      task.status != MeetingTaskStatus.completed;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TaskDetailScreen(
              task: task,
              onUpdate: (updatedTask) async {
                final meetingProvider = Provider.of<MeetingProvider>(context, listen: false);
                await meetingProvider.updateTask(updatedTask);
              },
              onDelete: (taskToDelete) async {
                final meetingProvider = Provider.of<MeetingProvider>(context, listen: false);
                await meetingProvider.deleteTask(taskToDelete.id);
              },
            ),
          ),
        ).then((_) => _loadTasks());
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: isOverdue 
              ? Border.all(color: Colors.red.withOpacity(0.5), width: 1)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (isOverdue)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 14, color: Colors.red),
                    const SizedBox(width: 4),
                    Text(
                      'Quá hạn',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                Icon(Icons.calendar_today_outlined, 
                     size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(task.deadline),
                  style: TextStyle(
                    fontSize: 13,
                    color: isOverdue ? Colors.red : Colors.grey.shade600,
                  ),
                ),
                const Spacer(),
                Icon(Icons.flag_outlined, 
                     size: 14, 
                     color: _getPriorityColor(task.priority)),
                const SizedBox(width: 4),
                Text(
                  _getPriorityText(task.priority),
                  style: TextStyle(
                    fontSize: 13,
                    color: _getPriorityColor(task.priority),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high': return Colors.red;
      case 'medium': return Colors.orange;
      case 'low': return Colors.green;
      default: return Colors.grey;
    }
  }

  String _getPriorityText(String priority) {
    switch (priority) {
      case 'high': return 'Cao';
      case 'medium': return 'Bình thường';
      case 'low': return 'Thấp';
      default: return 'Không xác định';
    }
  }
}
