import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart' as picker;
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../providers/file_provider.dart';
import '../providers/auth_provider.dart';
import '../models/file_model.dart';

class FileManagementScreen extends StatefulWidget {
  const FileManagementScreen({Key? key}) : super(key: key);

  @override
  State<FileManagementScreen> createState() => _FileManagementScreenState();
}

class _FileManagementScreenState extends State<FileManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  FileType _selectedFileType = FileType.other;
  String _selectedCategory = 'all';

  final List<String> _categories = [
    'all',
    'documents',
    'images',
    'videos',
    'presentations',
    'spreadsheets',
    'others'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFiles();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadFiles() {
    final fileProvider = Provider.of<FileProvider>(context, listen: false);
    fileProvider.loadFiles();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý File'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Tất cả File', icon: Icon(Icons.folder, size: 20)),
            Tab(text: 'Thư mục', icon: Icon(Icons.folder_open, size: 20)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
            tooltip: 'Tìm kiếm',
          ),
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: _uploadFile,
            tooltip: 'Upload file',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'new_folder',
                child: Row(
                  children: [
                    Icon(Icons.create_new_folder, size: 20),
                    SizedBox(width: 8),
                    Text('Tạo thư mục'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh, size: 20),
                    SizedBox(width: 8),
                    Text('Tải lại'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<FileProvider>(
        builder: (context, fileProvider, child) {
          if (fileProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              _buildStorageInfo(fileProvider),
              _buildCategoryFilter(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAllFilesView(fileProvider),
                    _buildFoldersView(fileProvider),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _uploadFile,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildStorageInfo(FileProvider fileProvider) {
    final fileCount = fileProvider.files.length;
    final totalSize =
        fileProvider.files.fold<int>(0, (sum, file) => sum + file.size);
    final folderCount = fileProvider.folders.length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.folder, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                'Thông tin lưu trữ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Files: $fileCount',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade600,
                    ),
                  ),
                  Text(
                    'Folders: $folderCount',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade600,
                    ),
                  ),
                ],
              ),
              Text(
                'Tổng: ${_formatBytes(totalSize)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;

          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(_getCategoryDisplayName(category)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = category;
                });
              },
              selectedColor: Colors.blue.withOpacity(0.2),
              checkmarkColor: Colors.blue,
            ),
          );
        },
      ),
    );
  }

  Widget _buildAllFilesView(FileProvider fileProvider) {
    final filteredFiles = _getFilteredFiles(fileProvider.files);

    if (filteredFiles.isEmpty) {
      return _buildEmptyState('Chưa có file nào');
    }

    return _buildFileGrid(filteredFiles);
  }

  Widget _buildFoldersView(FileProvider fileProvider) {
    final folders = fileProvider.folders;

    if (folders.isEmpty) {
      return _buildEmptyState('Chưa có thư mục nào');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: folders.length,
      itemBuilder: (context, index) {
        final folder = folders[index];
        return _buildFolderCard(folder);
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _uploadFile,
            icon: const Icon(Icons.upload_file),
            label: const Text('Upload file đầu tiên'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileGrid(List<FileModel> files) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        return _buildFileCard(file);
      },
    );
  }

  Widget _buildFileCard(FileModel file) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showFileDetails(file),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // File icon and actions
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getFileTypeColor(file.type).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getFileTypeIcon(file.type),
                      color: _getFileTypeColor(file.type),
                      size: 24,
                    ),
                  ),
                  const Spacer(),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 16),
                    onSelected: (value) => _handleFileAction(value, file),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'download',
                        child: Row(
                          children: [
                            Icon(Icons.download, size: 16),
                            SizedBox(width: 8),
                            Text('Tải xuống'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'share',
                        child: Row(
                          children: [
                            Icon(Icons.share, size: 16),
                            SizedBox(width: 8),
                            Text('Chia sẻ'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 16, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Xóa', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // File name
              Text(
                file.originalName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // File size and date
              Text(
                _formatBytes(file.size),
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                DateFormat('dd/MM/yyyy').format(file.createdAt),
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 11,
                ),
              ),

              const Spacer(),

              // File type badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  file.type.name.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFolderCard(FolderModel folder) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.folder, color: Colors.blue, size: 32),
        title: Text(folder.name),
        subtitle:
            Text('${folder.fileCount} files • ${folder.totalSizeFormatted}'),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) => _handleFolderAction(value, folder),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'open',
              child: Row(
                children: [
                  Icon(Icons.folder_open, size: 16),
                  SizedBox(width: 8),
                  Text('Mở'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'rename',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 16),
                  SizedBox(width: 8),
                  Text('Đổi tên'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 16, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Xóa', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _openFolder(folder),
      ),
    );
  }

  List<FileModel> _getFilteredFiles(List<FileModel> files) {
    var filtered = files;

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((file) =>
              file.originalName
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              file.type.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // Filter by category
    if (_selectedCategory != 'all') {
      filtered = filtered.where((file) {
        switch (_selectedCategory) {
          case 'documents':
            return file.type == FileType.document;
          case 'images':
            return file.type == FileType.image;
          case 'videos':
            return file.type == FileType.video;
          case 'presentations':
            return file.type == FileType.presentation;
          case 'spreadsheets':
            return file.type == FileType.spreadsheet;
          default:
            return true;
        }
      }).toList();
    }

    return filtered;
  }

  String _getCategoryDisplayName(String category) {
    switch (category) {
      case 'all':
        return 'Tất cả';
      case 'documents':
        return 'Tài liệu';
      case 'images':
        return 'Hình ảnh';
      case 'videos':
        return 'Video';
      case 'presentations':
        return 'Thuyết trình';
      case 'spreadsheets':
        return 'Bảng tính';
      case 'others':
        return 'Khác';
      default:
        return category;
    }
  }

  IconData _getFileTypeIcon(FileType type) {
    switch (type) {
      case FileType.document:
        return Icons.description;
      case FileType.image:
        return Icons.image;
      case FileType.video:
        return Icons.video_file;
      case FileType.audio:
        return Icons.audio_file;
      case FileType.spreadsheet:
        return Icons.table_chart;
      case FileType.presentation:
        return Icons.slideshow;
      case FileType.archive:
        return Icons.archive;
      case FileType.other:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileTypeColor(FileType type) {
    switch (type) {
      case FileType.document:
        return Colors.blue;
      case FileType.image:
        return Colors.purple;
      case FileType.video:
        return Colors.pink;
      case FileType.audio:
        return Colors.teal;
      case FileType.spreadsheet:
        return Colors.green;
      case FileType.presentation:
        return Colors.orange;
      case FileType.archive:
        return Colors.brown;
      case FileType.other:
        return Colors.grey;
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = (math.log(bytes) / math.log(1024)).floor();
    return '${(bytes / math.pow(1024, i)).toStringAsFixed(1)} ${suffixes[i]}';
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String tempQuery = _searchQuery;
        return AlertDialog(
          title: const Text('Tìm kiếm file'),
          content: TextField(
            decoration: const InputDecoration(
              hintText: 'Nhập tên file...',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) => tempQuery = value,
            controller: TextEditingController(text: _searchQuery),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _searchQuery = tempQuery;
                });
                Navigator.pop(context);
              },
              child: const Text('Tìm kiếm'),
            ),
          ],
        );
      },
    );
  }

  void _uploadFile() async {
    try {
      picker.FilePickerResult? result =
          await picker.FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: picker.FileType.custom,
        allowedExtensions: [
          'pdf',
          'doc',
          'docx',
          'xls',
          'xlsx',
          'ppt',
          'pptx',
          'txt',
          'jpg',
          'png',
          'gif',
          'mp4',
          'mp3'
        ],
      );

      if (result != null && result.files.isNotEmpty) {
        final fileProvider = Provider.of<FileProvider>(context, listen: false);
        final authProvider = Provider.of<AuthProvider>(context, listen: false);

        if (authProvider.userModel != null) {
          await fileProvider.uploadFiles(
            result.files,
            authProvider.userModel!.id,
            authProvider.userModel!.displayName,
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Đã upload ${result.files.length} file(s) thành công'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi upload file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'new_folder':
        _showCreateFolderDialog();
        break;
      case 'refresh':
        _loadFiles();
        break;
    }
  }

  void _handleFileAction(String action, FileModel file) async {
    final fileProvider = Provider.of<FileProvider>(context, listen: false);

    switch (action) {
      case 'download':
        try {
          await fileProvider.downloadFile(file);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File đã được tải xuống')),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi tải file: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
        break;
      case 'share':
        _showShareDialog(file);
        break;
      case 'delete':
        _showDeleteConfirmDialog(file);
        break;
    }
  }

  void _handleFolderAction(String action, FolderModel folder) {
    switch (action) {
      case 'open':
        _openFolder(folder);
        break;
      case 'rename':
        _showRenameFolderDialog(folder);
        break;
      case 'delete':
        _showDeleteFolderDialog(folder);
        break;
    }
  }

  void _openFolder(FolderModel folder) {
    final fileProvider = Provider.of<FileProvider>(context, listen: false);
    fileProvider.navigateToFolder(folder.id);
  }

  void _showFileDetails(FileModel file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(file.originalName),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Loại: ${file.typeDisplayName}'),
            Text('Kích thước: ${_formatBytes(file.size)}'),
            Text(
                'Ngày upload: ${DateFormat('dd/MM/yyyy HH:mm').format(file.createdAt)}'),
            Text('Người upload: ${file.uploaderName}'),
            if (file.description?.isNotEmpty == true)
              Text('Mô tả: ${file.description}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleFileAction('download', file);
            },
            child: const Text('Tải xuống'),
          ),
        ],
      ),
    );
  }

  void _showCreateFolderDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tạo thư mục mới'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Tên thư mục...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                final fileProvider =
                    Provider.of<FileProvider>(context, listen: false);
                final authProvider =
                    Provider.of<AuthProvider>(context, listen: false);

                if (authProvider.userModel != null) {
                  await fileProvider.createFolder(
                    name,
                    authProvider.userModel!.id,
                    authProvider.userModel!.displayName,
                  );
                  Navigator.pop(context);
                }
              }
            },
            child: const Text('Tạo'),
          ),
        ],
      ),
    );
  }

  void _showShareDialog(FileModel file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chia sẻ ${file.originalName}'),
        content: const Text('Tính năng chia sẻ file đang phát triển'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showRenameFolderDialog(FolderModel folder) {
    final controller = TextEditingController(text: folder.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đổi tên thư mục'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tính năng đang phát triển')),
              );
            },
            child: const Text('Đổi tên'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(FileModel file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa file "${file.originalName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              final fileProvider =
                  Provider.of<FileProvider>(context, listen: false);
              await fileProvider.deleteFile(file.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã xóa file thành công'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteFolderDialog(FolderModel folder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa thư mục "${folder.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tính năng đang phát triển')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
