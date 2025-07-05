import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

class SimpleFileProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  List<Map<String, dynamic>> _files = [];
  bool _isLoading = false;
  String _error = '';

  // Getters
  List<Map<String, dynamic>> get files => _files;
  bool get isLoading => _isLoading;
  String get error => _error;

  /// Load files
  Future<void> loadFiles({String? folderId, String? meetingId}) async {
    try {
      _setLoading(true);
      _setError('');

      Query query = _firestore.collection('files');

      if (folderId != null) {
        query = query.where('folderId', isEqualTo: folderId);
      } else if (meetingId != null) {
        query = query.where('meetingId', isEqualTo: meetingId);
      }

      QuerySnapshot snapshot =
          await query.orderBy('createdAt', descending: true).get();

      _files = snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();

      notifyListeners();
      print('✅ Loaded ${_files.length} files');
    } catch (e) {
      print('❌ Error loading files: $e');
      _setError('Lỗi tải files: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Upload files
  Future<List<String>> uploadFiles(
    List<PlatformFile> platformFiles,
    String uploaderId,
    String uploaderName, {
    String? meetingId,
    String? folderId,
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
        );
        uploadedFileIds.add(fileId);
      } catch (e) {
        print('❌ Error uploading ${platformFile.name}: $e');
      }
    }

    // Reload files after upload
    await loadFiles(folderId: folderId, meetingId: meetingId);

    return uploadedFileIds;
  }

  /// Upload single file
  Future<String> _uploadSingleFile(
    PlatformFile platformFile,
    String uploaderId,
    String uploaderName, {
    String? meetingId,
    String? folderId,
  }) async {
    final String fileId = _firestore.collection('files').doc().id;
    final String fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${platformFile.name}';
    final String storagePath = _getStoragePath(fileName, folderId, meetingId);

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

      // Wait for upload completion
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      // Create file document
      Map<String, dynamic> fileData = {
        'name': fileName,
        'originalName': platformFile.name,
        'type': _getFileType(platformFile.name),
        'status': 'ready',
        'mimeType': platformFile.extension ?? 'application/octet-stream',
        'size': platformFile.size,
        'downloadUrl': downloadUrl,
        'uploaderId': uploaderId,
        'uploaderName': uploaderName,
        'meetingId': meetingId,
        'folderId': folderId,
        'downloadCount': 0,
        'viewCount': 0,
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      // Save to Firestore
      await _firestore.collection('files').doc(fileId).set(fileData);

      print('✅ Uploaded file: ${platformFile.name}');
      return fileId;
    } catch (e) {
      print('❌ Error uploading ${platformFile.name}: $e');
      rethrow;
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

  /// Get file type
  String _getFileType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();

    switch (extension) {
      case 'pdf':
      case 'doc':
      case 'docx':
      case 'txt':
        return 'document';
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return 'image';
      case 'mp4':
      case 'avi':
      case 'mov':
        return 'video';
      case 'mp3':
      case 'wav':
      case 'aac':
        return 'audio';
      case 'xls':
      case 'xlsx':
      case 'csv':
        return 'spreadsheet';
      case 'ppt':
      case 'pptx':
        return 'presentation';
      default:
        return 'other';
    }
  }

  /// Download file
  Future<File?> downloadFile(Map<String, dynamic> fileData) async {
    try {
      _setLoading(true);
      _setError('');

      // Get app directory
      Directory appDir = await getApplicationDocumentsDirectory();
      String filePath = '${appDir.path}/downloads/${fileData['name']}';

      // Create directory if not exists
      Directory downloadDir = Directory('${appDir.path}/downloads');
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }

      // Download file
      final Reference storageRef = _storage.refFromURL(fileData['downloadUrl']);
      final File localFile = File(filePath);

      await storageRef.writeToFile(localFile);

      // Update download count
      await _firestore.collection('files').doc(fileData['id']).update({
        'downloadCount': (fileData['downloadCount'] ?? 0) + 1,
        'lastAccessedAt': Timestamp.fromDate(DateTime.now()),
      });

      print('✅ Downloaded file: ${fileData['name']}');
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

      Map<String, dynamic> fileData = doc.data() as Map<String, dynamic>;

      // Delete from Storage
      try {
        final Reference storageRef =
            _storage.refFromURL(fileData['downloadUrl']);
        await storageRef.delete();
      } catch (e) {
        print('⚠️ Warning: Could not delete file from storage: $e');
      }

      // Delete from Firestore
      await _firestore.collection('files').doc(fileId).delete();

      // Remove from local list
      _files.removeWhere((f) => f['id'] == fileId);

      notifyListeners();
      print('✅ Deleted file: ${fileData['name']}');
    } catch (e) {
      print('❌ Error deleting file: $e');
      _setError('Lỗi xóa file: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Get files by meeting
  Future<List<Map<String, dynamic>>> getFilesByMeeting(String meetingId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('files')
          .where('meetingId', isEqualTo: meetingId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    } catch (e) {
      print('❌ Error getting files by meeting: $e');
      return [];
    }
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
      print('❌ SimpleFileProvider Error: $error');
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
