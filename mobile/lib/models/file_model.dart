import 'package:cloud_firestore/cloud_firestore.dart';

/// Loại file
enum FileType {
  document, // PDF, DOC, DOCX, TXT
  image, // JPG, PNG, GIF
  video, // MP4, AVI, MOV
  audio, // MP3, WAV, AAC
  spreadsheet, // XLS, XLSX, CSV
  presentation, // PPT, PPTX
  archive, // ZIP, RAR, 7Z
  other, // Khác
}

/// Trạng thái file
enum FileStatus {
  uploading, // Đang upload
  processing, // Đang xử lý
  ready, // Sẵn sàng
  error, // Lỗi
  deleted, // Đã xóa
}

/// Quyền truy cập file
enum FilePermission {
  owner, // Chủ sở hữu
  edit, // Chỉnh sửa
  view, // Chỉ xem
  comment, // Bình luận
  download, // Tải về
}

/// Model file
class FileModel {
  final String id;
  final String name;
  final String originalName;
  final String? description;
  final FileType type;
  final FileStatus status;
  final String mimeType;
  final int size; // bytes
  final String downloadUrl;
  final String? thumbnailUrl;
  final String uploaderId;
  final String uploaderName;
  final String? meetingId;
  final String? folderId;
  final String? folderPath;
  final List<String> tags;
  final Map<String, FilePermission> permissions;
  final int downloadCount;
  final int viewCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastAccessedAt;
  final Map<String, dynamic>? metadata;
  final bool isPublic;
  final DateTime? expiresAt;

  FileModel({
    required this.id,
    required this.name,
    required this.originalName,
    this.description,
    required this.type,
    this.status = FileStatus.ready,
    required this.mimeType,
    required this.size,
    required this.downloadUrl,
    this.thumbnailUrl,
    required this.uploaderId,
    required this.uploaderName,
    this.meetingId,
    this.folderId,
    this.folderPath,
    this.tags = const [],
    this.permissions = const {},
    this.downloadCount = 0,
    this.viewCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.lastAccessedAt,
    this.metadata,
    this.isPublic = false,
    this.expiresAt,
  });

  factory FileModel.fromMap(Map<String, dynamic> map, String id) {
    return FileModel(
      id: id,
      name: map['name'] ?? '',
      originalName: map['originalName'] ?? '',
      description: map['description'],
      type: FileType.values.firstWhere(
        (type) => type.toString().split('.').last == map['type'],
        orElse: () => FileType.other,
      ),
      status: FileStatus.values.firstWhere(
        (status) => status.toString().split('.').last == map['status'],
        orElse: () => FileStatus.ready,
      ),
      mimeType: map['mimeType'] ?? '',
      size: map['size'] ?? 0,
      downloadUrl: map['downloadUrl'] ?? '',
      thumbnailUrl: map['thumbnailUrl'],
      uploaderId: map['uploaderId'] ?? '',
      uploaderName: map['uploaderName'] ?? '',
      meetingId: map['meetingId'],
      folderId: map['folderId'],
      folderPath: map['folderPath'],
      tags: List<String>.from(map['tags'] ?? []),
      permissions: Map<String, FilePermission>.from(
        (map['permissions'] as Map<String, dynamic>?)?.map(
              (key, value) => MapEntry(
                key,
                FilePermission.values.firstWhere(
                  (perm) => perm.toString().split('.').last == value,
                  orElse: () => FilePermission.view,
                ),
              ),
            ) ??
            {},
      ),
      downloadCount: map['downloadCount'] ?? 0,
      viewCount: map['viewCount'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      lastAccessedAt: map['lastAccessedAt'] != null
          ? (map['lastAccessedAt'] as Timestamp).toDate()
          : null,
      metadata: map['metadata'] != null
          ? Map<String, dynamic>.from(map['metadata'])
          : null,
      isPublic: map['isPublic'] ?? false,
      expiresAt: map['expiresAt'] != null
          ? (map['expiresAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'originalName': originalName,
      'description': description,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'mimeType': mimeType,
      'size': size,
      'downloadUrl': downloadUrl,
      'thumbnailUrl': thumbnailUrl,
      'uploaderId': uploaderId,
      'uploaderName': uploaderName,
      'meetingId': meetingId,
      'folderId': folderId,
      'folderPath': folderPath,
      'tags': tags,
      'permissions': permissions.map(
        (key, value) => MapEntry(key, value.toString().split('.').last),
      ),
      'downloadCount': downloadCount,
      'viewCount': viewCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'lastAccessedAt':
          lastAccessedAt != null ? Timestamp.fromDate(lastAccessedAt!) : null,
      'metadata': metadata,
      'isPublic': isPublic,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
    };
  }

  FileModel copyWith({
    String? id,
    String? name,
    String? originalName,
    String? description,
    FileType? type,
    FileStatus? status,
    String? mimeType,
    int? size,
    String? downloadUrl,
    String? thumbnailUrl,
    String? uploaderId,
    String? uploaderName,
    String? meetingId,
    String? folderId,
    String? folderPath,
    List<String>? tags,
    Map<String, FilePermission>? permissions,
    int? downloadCount,
    int? viewCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastAccessedAt,
    Map<String, dynamic>? metadata,
    bool? isPublic,
    DateTime? expiresAt,
  }) {
    return FileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      originalName: originalName ?? this.originalName,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      mimeType: mimeType ?? this.mimeType,
      size: size ?? this.size,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      uploaderId: uploaderId ?? this.uploaderId,
      uploaderName: uploaderName ?? this.uploaderName,
      meetingId: meetingId ?? this.meetingId,
      folderId: folderId ?? this.folderId,
      folderPath: folderPath ?? this.folderPath,
      tags: tags ?? this.tags,
      permissions: permissions ?? this.permissions,
      downloadCount: downloadCount ?? this.downloadCount,
      viewCount: viewCount ?? this.viewCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      metadata: metadata ?? this.metadata,
      isPublic: isPublic ?? this.isPublic,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  // Helper methods
  String get sizeFormatted {
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
    if (size < 1024 * 1024 * 1024)
      return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  String get typeDisplayName {
    switch (type) {
      case FileType.document:
        return 'Tài liệu';
      case FileType.image:
        return 'Hình ảnh';
      case FileType.video:
        return 'Video';
      case FileType.audio:
        return 'Âm thanh';
      case FileType.spreadsheet:
        return 'Bảng tính';
      case FileType.presentation:
        return 'Thuyết trình';
      case FileType.archive:
        return 'Nén';
      case FileType.other:
        return 'Khác';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case FileStatus.uploading:
        return 'Đang tải lên';
      case FileStatus.processing:
        return 'Đang xử lý';
      case FileStatus.ready:
        return 'Sẵn sàng';
      case FileStatus.error:
        return 'Lỗi';
      case FileStatus.deleted:
        return 'Đã xóa';
    }
  }

  bool get isImage => type == FileType.image;
  bool get isVideo => type == FileType.video;
  bool get isAudio => type == FileType.audio;
  bool get isDocument => type == FileType.document;

  bool get canPreview => isImage || isDocument;
  bool get isReady => status == FileStatus.ready;
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  String get fileExtension {
    return name.split('.').last.toLowerCase();
  }

  /// Xác định FileType từ mime type hoặc extension
  static FileType getFileTypeFromMime(String mimeType, String fileName) {
    final extension = fileName.split('.').last.toLowerCase();

    if (mimeType.startsWith('image/')) return FileType.image;
    if (mimeType.startsWith('video/')) return FileType.video;
    if (mimeType.startsWith('audio/')) return FileType.audio;

    switch (extension) {
      case 'pdf':
      case 'doc':
      case 'docx':
      case 'txt':
      case 'rtf':
        return FileType.document;
      case 'xls':
      case 'xlsx':
      case 'csv':
        return FileType.spreadsheet;
      case 'ppt':
      case 'pptx':
        return FileType.presentation;
      case 'zip':
      case 'rar':
      case '7z':
      case 'tar':
      case 'gz':
        return FileType.archive;
      default:
        return FileType.other;
    }
  }
}

/// Model folder
class FolderModel {
  final String id;
  final String name;
  final String? description;
  final String? parentId;
  final String path;
  final String creatorId;
  final String creatorName;
  final List<String> tags;
  final Map<String, FilePermission> permissions;
  final bool isPublic;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int fileCount;
  final int totalSize;

  FolderModel({
    required this.id,
    required this.name,
    this.description,
    this.parentId,
    required this.path,
    required this.creatorId,
    required this.creatorName,
    this.tags = const [],
    this.permissions = const {},
    this.isPublic = false,
    required this.createdAt,
    required this.updatedAt,
    this.fileCount = 0,
    this.totalSize = 0,
  });

  factory FolderModel.fromMap(Map<String, dynamic> map, String id) {
    return FolderModel(
      id: id,
      name: map['name'] ?? '',
      description: map['description'],
      parentId: map['parentId'],
      path: map['path'] ?? '',
      creatorId: map['creatorId'] ?? '',
      creatorName: map['creatorName'] ?? '',
      tags: List<String>.from(map['tags'] ?? []),
      permissions: Map<String, FilePermission>.from(
        (map['permissions'] as Map<String, dynamic>?)?.map(
              (key, value) => MapEntry(
                key,
                FilePermission.values.firstWhere(
                  (perm) => perm.toString().split('.').last == value,
                  orElse: () => FilePermission.view,
                ),
              ),
            ) ??
            {},
      ),
      isPublic: map['isPublic'] ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      fileCount: map['fileCount'] ?? 0,
      totalSize: map['totalSize'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'parentId': parentId,
      'path': path,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'tags': tags,
      'permissions': permissions.map(
        (key, value) => MapEntry(key, value.toString().split('.').last),
      ),
      'isPublic': isPublic,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'fileCount': fileCount,
      'totalSize': totalSize,
    };
  }

  String get totalSizeFormatted {
    if (totalSize < 1024) return '${totalSize}B';
    if (totalSize < 1024 * 1024)
      return '${(totalSize / 1024).toStringAsFixed(1)}KB';
    if (totalSize < 1024 * 1024 * 1024)
      return '${(totalSize / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(totalSize / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }
}

/// Upload progress model
class UploadProgress {
  final String fileId;
  final String fileName;
  final int totalBytes;
  final int uploadedBytes;
  final FileStatus status;
  final String? error;

  UploadProgress({
    required this.fileId,
    required this.fileName,
    required this.totalBytes,
    required this.uploadedBytes,
    this.status = FileStatus.uploading,
    this.error,
  });

  double get progress => totalBytes > 0 ? uploadedBytes / totalBytes : 0.0;
  int get progressPercent => (progress * 100).round();
  bool get isCompleted => status == FileStatus.ready;
  bool get hasError => status == FileStatus.error;
}

/// File search filter
class FileSearchFilter {
  final String? query;
  final List<FileType>? types;
  final String? uploaderId;
  final String? meetingId;
  final String? folderId;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String>? tags;
  final int? minSize;
  final int? maxSize;

  FileSearchFilter({
    this.query,
    this.types,
    this.uploaderId,
    this.meetingId,
    this.folderId,
    this.startDate,
    this.endDate,
    this.tags,
    this.minSize,
    this.maxSize,
  });
}
