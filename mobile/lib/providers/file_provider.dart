import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart' hide FileType;
import 'package:path_provider/path_provider.dart';
import 'package:metting_app/models/file_model.dart';
import 'package:metting_app/models/user_model.dart';

class FileProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  List<FileModel> _files = [];
  List<FolderModel> _folders = [];
  List<UploadProgress> _uploadProgresses = [];
  Map<String, File> _downloadedFiles = {};

  bool _isLoading = false;
  String _error = '';
  String? _currentFolderId;
  String _currentPath = '/';

  // Getters
  List<FileModel> get files => _files;
  List<FolderModel> get folders => _folders;
  List<UploadProgress> get uploadProgresses => _uploadProgresses;
  Map<String, File> get downloadedFiles => _downloadedFiles;
  bool get isLoading => _isLoading;
  String get error => _error;
  String? get currentFolderId => _currentFolderId;
  String get currentPath => _currentPath;

  /// Load files và folders trong folder hiện tại
  Future<void> loadFiles({String? folderId, String? meetingId}) async {
    try {
      _setLoading(true);
      _setError('');
      _currentFolderId = folderId;

      // Load folders
      await _loadFolders(folderId);

      // Load files
      await _loadFilesInFolder(folderId, meetingId);

      // Update current path
      await _updateCurrentPath();

      notifyListeners();
      print('✅ Loaded ${_files.length} files and ${_folders.length} folders');
    } catch (e) {
      print('❌ Error loading files: $e');
      _setError('Lỗi tải files: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load folders
  Future<void> _loadFolders(String? parentId) async {
    try {
      Query query = _firestore.collection('folders');

      if (parentId != null) {
        query = query.where('parentId', isEqualTo: parentId);
      } else {
        query = query.where('parentId', isNull: true);
      }

      QuerySnapshot snapshot = await query.get();

      _folders = snapshot.docs
          .map((doc) =>
              FolderModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('❌ Error loading folders: $e');
    }
  }

  /// Load files trong folder
  Future<void> _loadFilesInFolder(String? folderId, String? meetingId) async {
    try {
      Query query =
          _firestore.collection('files').where('status', isEqualTo: 'ready');

      if (folderId != null) {
        query = query.where('folderId', isEqualTo: folderId);
      } else if (meetingId != null) {
        query = query.where('meetingId', isEqualTo: meetingId);
      } else {
        query = query.where('folderId', isNull: true);
      }

      QuerySnapshot snapshot =
          await query.orderBy('createdAt', descending: true).get();

      _files = snapshot.docs
          .map((doc) =>
              FileModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('❌ Error loading files: $e');
    }
  }

  /// Update current path
  Future<void> _updateCurrentPath() async {
    if (_currentFolderId == null) {
      _currentPath = '/';
      return;
    }

    try {
      DocumentSnapshot doc =
          await _firestore.collection('folders').doc(_currentFolderId).get();

      if (doc.exists) {
        FolderModel folder =
            FolderModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        _currentPath = folder.path;
      }
    } catch (e) {
      print('❌ Error updating path: $e');
    }
  }

  /// Upload files
  Future<List<String>> uploadFiles(
    List<PlatformFile> platformFiles,
    String uploaderId,
    String uploaderName, {
    String? meetingId,
    String? folderId,
    Map<String, String>? metadata,
  }) async {
    List<String> uploadedFileIds = [];

    for (PlatformFile platformFile in platformFiles) {
      try {
        String fileId = await _uploadSingleFile(
          platformFile,
          uploaderId,
          uploaderName,
          meetingId: meetingId,
          folderId: folderId,
          metadata: metadata,
        );
        uploadedFileIds.add(fileId);
      } catch (e) {
        print('❌ Error uploading ${platformFile.name}: $e');
      }
    }

    // Reload files after upload
    await loadFiles(folderId: _currentFolderId);

    return uploadedFileIds;
  }

  /// Upload single file
  Future<String> _uploadSingleFile(
    PlatformFile platformFile,
    String uploaderId,
    String uploaderName, {
    String? meetingId,
    String? folderId,
    Map<String, String>? metadata,
  }) async {
    final String fileId = _firestore.collection('files').doc().id;
    final String fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${platformFile.name}';
    final String storagePath = _getStoragePath(fileName, folderId, meetingId);

    // Create upload progress
    UploadProgress progress = UploadProgress(
      fileId: fileId,
      fileName: platformFile.name,
      totalBytes: platformFile.size,
      uploadedBytes: 0,
      status: FileStatus.uploading,
    );
    _uploadProgresses.add(progress);
    notifyListeners();

    try {
      // Upload to Firebase Storage
      final Reference storageRef = _storage.ref().child(storagePath);
      final UploadTask uploadTask;

      if (platformFile.bytes != null) {
        uploadTask = storageRef.putData(platformFile.bytes!);
      } else if (platformFile.path != null) {
        uploadTask = storageRef.putFile(File(platformFile.path!));
      } else {
        throw Exception('No file data available');
      }

      // Listen to upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        int uploadedBytes = snapshot.bytesTransferred;
        _updateUploadProgress(fileId, uploadedBytes);
      });

      // Wait for upload completion
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      // Generate thumbnail if image
      String? thumbnailUrl;
      if (platformFile.name.toLowerCase().endsWith('.jpg') ||
          platformFile.name.toLowerCase().endsWith('.jpeg') ||
          platformFile.name.toLowerCase().endsWith('.png')) {
        thumbnailUrl = await _generateThumbnail(downloadUrl, fileName);
      }

      // Create file document
      FileModel fileModel = FileModel(
        id: fileId,
        name: fileName,
        originalName: platformFile.name,
        type: FileModel.getFileTypeFromMime(
            platformFile.extension ?? '', platformFile.name),
        status: FileStatus.ready,
        mimeType: platformFile.extension ?? 'application/octet-stream',
        size: platformFile.size,
        downloadUrl: downloadUrl,
        thumbnailUrl: thumbnailUrl,
        uploaderId: uploaderId,
        uploaderName: uploaderName,
        meetingId: meetingId,
        folderId: folderId,
        folderPath: _currentPath,
        metadata: metadata,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save to Firestore
      await _firestore.collection('files').doc(fileId).set(fileModel.toMap());

      // Update upload progress to completed
      _updateUploadProgress(fileId, platformFile.size, FileStatus.ready);

      print('✅ Uploaded file: ${platformFile.name}');
      return fileId;
    } catch (e) {
      print('❌ Error uploading ${platformFile.name}: $e');
      _updateUploadProgress(fileId, 0, FileStatus.error, e.toString());
      rethrow;
    }
  }

  /// Generate thumbnail cho image
  Future<String?> _generateThumbnail(
      String originalUrl, String fileName) async {
    try {
      // TODO: Implement thumbnail generation
      // For now, return original URL
      return originalUrl;
    } catch (e) {
      print('❌ Error generating thumbnail: $e');
      return null;
    }
  }

  /// Get storage path
  String _getStoragePath(String fileName, String? folderId, String? meetingId) {
    if (meetingId != null) {
      return 'meetings/$meetingId/files/$fileName';
    } else if (folderId != null) {
      return 'folders/$folderId/files/$fileName';
    } else {
      return 'files/$fileName';
    }
  }

  /// Update upload progress
  void _updateUploadProgress(String fileId, int uploadedBytes,
      [FileStatus? status, String? error]) {
    int index = _uploadProgresses.indexWhere((p) => p.fileId == fileId);
    if (index != -1) {
      UploadProgress oldProgress = _uploadProgresses[index];
      _uploadProgresses[index] = UploadProgress(
        fileId: fileId,
        fileName: oldProgress.fileName,
        totalBytes: oldProgress.totalBytes,
        uploadedBytes: uploadedBytes,
        status: status ?? oldProgress.status,
        error: error,
      );
      notifyListeners();
    }
  }

  /// Download file
  Future<File?> downloadFile(FileModel fileModel) async {
    try {
      _setLoading(true);
      _setError('');

      // Check if already downloaded
      if (_downloadedFiles.containsKey(fileModel.id)) {
        File existingFile = _downloadedFiles[fileModel.id]!;
        if (await existingFile.exists()) {
          return existingFile;
        }
      }

      // Get app directory
      Directory appDir = await getApplicationDocumentsDirectory();
      String filePath = '${appDir.path}/downloads/${fileModel.name}';

      // Create directory if not exists
      Directory downloadDir = Directory('${appDir.path}/downloads');
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }

      // Download file
      final Reference storageRef = _storage.refFromURL(fileModel.downloadUrl);
      final File localFile = File(filePath);

      await storageRef.writeToFile(localFile);

      // Update download count
      await _updateFileStats(fileModel.id,
          downloadCount: fileModel.downloadCount + 1);

      // Cache downloaded file
      _downloadedFiles[fileModel.id] = localFile;

      print('✅ Downloaded file: ${fileModel.name}');
      return localFile;
    } catch (e) {
      print('❌ Error downloading file: $e');
      _setError('Lỗi tải file: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Delete file
  Future<void> deleteFile(String fileId) async {
    try {
      _setLoading(true);
      _setError('');

      // Get file info
      DocumentSnapshot doc =
          await _firestore.collection('files').doc(fileId).get();
      if (!doc.exists) {
        throw Exception('File not found');
      }

      FileModel fileModel =
          FileModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);

      // Delete from Storage
      try {
        final Reference storageRef = _storage.refFromURL(fileModel.downloadUrl);
        await storageRef.delete();
      } catch (e) {
        print('⚠️ Warning: Could not delete file from storage: $e');
      }

      // Delete thumbnail if exists
      if (fileModel.thumbnailUrl != null) {
        try {
          final Reference thumbnailRef =
              _storage.refFromURL(fileModel.thumbnailUrl!);
          await thumbnailRef.delete();
        } catch (e) {
          print('⚠️ Warning: Could not delete thumbnail: $e');
        }
      }

      // Delete from Firestore
      await _firestore.collection('files').doc(fileId).delete();

      // Remove from local cache
      _downloadedFiles.remove(fileId);
      _files.removeWhere((f) => f.id == fileId);

      notifyListeners();
      print('✅ Deleted file: ${fileModel.name}');
    } catch (e) {
      print('❌ Error deleting file: $e');
      _setError('Lỗi xóa file: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Create folder
  Future<String?> createFolder(
    String name,
    String creatorId,
    String creatorName, {
    String? parentId,
    String? description,
  }) async {
    try {
      _setLoading(true);
      _setError('');

      // Build folder path
      String folderPath = '/';
      if (parentId != null) {
        DocumentSnapshot parentDoc =
            await _firestore.collection('folders').doc(parentId).get();
        if (parentDoc.exists) {
          FolderModel parentFolder = FolderModel.fromMap(
              parentDoc.data() as Map<String, dynamic>, parentDoc.id);
          folderPath = '${parentFolder.path}$name/';
        }
      } else {
        folderPath = '/$name/';
      }

      FolderModel folder = FolderModel(
        id: '',
        name: name,
        description: description,
        parentId: parentId,
        path: folderPath,
        creatorId: creatorId,
        creatorName: creatorName,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      DocumentReference docRef =
          await _firestore.collection('folders').add(folder.toMap());

      // Reload folders
      await _loadFolders(_currentFolderId);
      notifyListeners();

      print('✅ Created folder: $name');
      return docRef.id;
    } catch (e) {
      print('❌ Error creating folder: $e');
      _setError('Lỗi tạo folder: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Navigate to folder
  Future<void> navigateToFolder(String? folderId) async {
    await loadFiles(folderId: folderId);
  }

  /// Navigate up (parent folder)
  Future<void> navigateUp() async {
    if (_currentFolderId == null) return;

    try {
      DocumentSnapshot doc =
          await _firestore.collection('folders').doc(_currentFolderId).get();

      if (doc.exists) {
        FolderModel folder =
            FolderModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        await navigateToFolder(folder.parentId);
      }
    } catch (e) {
      print('❌ Error navigating up: $e');
    }
  }

  /// Search files
  Future<List<FileModel>> searchFiles(FileSearchFilter filter) async {
    try {
      Query query =
          _firestore.collection('files').where('status', isEqualTo: 'ready');

      // Apply filters
      if (filter.uploaderId != null) {
        query = query.where('uploaderId', isEqualTo: filter.uploaderId);
      }
      if (filter.meetingId != null) {
        query = query.where('meetingId', isEqualTo: filter.meetingId);
      }
      if (filter.folderId != null) {
        query = query.where('folderId', isEqualTo: filter.folderId);
      }
      if (filter.startDate != null) {
        query =
            query.where('createdAt', isGreaterThanOrEqualTo: filter.startDate);
      }
      if (filter.endDate != null) {
        query = query.where('createdAt', isLessThanOrEqualTo: filter.endDate);
      }

      QuerySnapshot snapshot = await query.get();
      List<FileModel> results = snapshot.docs
          .map((doc) =>
              FileModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      // Apply additional filters
      if (filter.query != null && filter.query!.isNotEmpty) {
        results = results
            .where((file) =>
                file.name.toLowerCase().contains(filter.query!.toLowerCase()) ||
                file.originalName
                    .toLowerCase()
                    .contains(filter.query!.toLowerCase()))
            .toList();
      }

      if (filter.types != null && filter.types!.isNotEmpty) {
        results =
            results.where((file) => filter.types!.contains(file.type)).toList();
      }

      if (filter.minSize != null) {
        results =
            results.where((file) => file.size >= filter.minSize!).toList();
      }

      if (filter.maxSize != null) {
        results =
            results.where((file) => file.size <= filter.maxSize!).toList();
      }

      return results;
    } catch (e) {
      print('❌ Error searching files: $e');
      return [];
    }
  }

  /// Get files by meeting
  Future<List<FileModel>> getFilesByMeeting(String meetingId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('files')
          .where('meetingId', isEqualTo: meetingId)
          .where('status', isEqualTo: 'ready')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) =>
              FileModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('❌ Error getting files by meeting: $e');
      return [];
    }
  }

  /// Update file stats
  Future<void> _updateFileStats(String fileId,
      {int? downloadCount, int? viewCount}) async {
    try {
      Map<String, dynamic> updates = {};
      if (downloadCount != null) updates['downloadCount'] = downloadCount;
      if (viewCount != null) updates['viewCount'] = viewCount;
      updates['lastAccessedAt'] = Timestamp.fromDate(DateTime.now());

      await _firestore.collection('files').doc(fileId).update(updates);
    } catch (e) {
      print('❌ Error updating file stats: $e');
    }
  }

  /// Get file preview URL
  String? getFilePreviewUrl(FileModel file) {
    if (file.thumbnailUrl != null) {
      return file.thumbnailUrl;
    }

    if (file.isImage) {
      return file.downloadUrl;
    }

    return null;
  }

  /// Check if file can be previewed
  bool canPreviewFile(FileModel file) {
    return file.canPreview && file.isReady;
  }

  /// Get storage usage
  Future<Map<String, dynamic>> getStorageUsage(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('files')
          .where('uploaderId', isEqualTo: userId)
          .where('status', isEqualTo: 'ready')
          .get();

      int totalFiles = snapshot.docs.length;
      int totalSize = 0;
      Map<FileType, int> typeCount = {};

      for (QueryDocumentSnapshot doc in snapshot.docs) {
        FileModel file =
            FileModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        totalSize += file.size;
        typeCount[file.type] = (typeCount[file.type] ?? 0) + 1;
      }

      return {
        'totalFiles': totalFiles,
        'totalSize': totalSize,
        'typeCount': typeCount,
      };
    } catch (e) {
      print('❌ Error getting storage usage: $e');
      return {'totalFiles': 0, 'totalSize': 0, 'typeCount': {}};
    }
  }

  /// Clear upload progresses
  void clearUploadProgresses() {
    _uploadProgresses.clear();
    notifyListeners();
  }

  /// Remove completed upload progress
  void removeCompletedUploads() {
    _uploadProgresses.removeWhere((progress) => progress.isCompleted);
    notifyListeners();
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error message
  void _setError(String error) {
    _error = error;
    if (error.isNotEmpty) {
      print('❌ FileProvider Error: $error');
    }
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = '';
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
