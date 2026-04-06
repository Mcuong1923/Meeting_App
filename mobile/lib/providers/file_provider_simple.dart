import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

// ─── File Upload Backend: transfer.sh ───────────────────────────
// Miễn phí, không cần tài khoản, không cần auth
// Files được lưu 365 ngày, link trực tiếp
// ────────────────────────────────────────────────────────────────

class SimpleFileProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _files = [];
  bool _isLoading = false;
  String _error = '';

  List<Map<String, dynamic>> get files => _files;
  bool get isLoading => _isLoading;
  String get error => _error;

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

      final snapshot =
          await query.orderBy('createdAt', descending: true).get();
      _files = snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
      notifyListeners();
      print('✅ Loaded ${_files.length} files');
    } catch (e) {
      print('❌ loadFiles error: $e');
      _setError('Lỗi tải files: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Upload nhiều file SONG SONG + cập nhật local ngay (không reload Firestore)
  Future<List<String>> uploadFiles(
    List<PlatformFile> platformFiles,
    String uploaderId,
    String uploaderName, {
    String? meetingId,
    String? folderId,
  }) async {
    // Tất cả file upload cùng lúc (song song)
    final results = await Future.wait(
      platformFiles.map((f) => _uploadSingleFile(
            f, uploaderId, uploaderName,
            meetingId: meetingId, folderId: folderId,
          )),
    );

    // Optimistic update: chèn trực tiếp vào _files, không query Firestore
    _files = [...results, ..._files];
    notifyListeners();

    return results.map((r) => r['id'] as String).toList();
  }

  /// Upload 1 file → trả về Map metadata (để cập nhật local ngay)
  Future<Map<String, dynamic>> _uploadSingleFile(
    PlatformFile platformFile,
    String uploaderId,
    String uploaderName, {
    String? meetingId,
    String? folderId,
  }) async {
    final fileId = _firestore.collection('files').doc().id;
    final safeName = platformFile.name.replaceAll(RegExp(r'\s+'), '_');
    final mimeType = _getMimeType(platformFile.name);
    final now = DateTime.now();

    try {
      // 0x0.st → catbox.moe (fallback)
      String downloadUrl;
      try {
        downloadUrl = await _uploadTo0x0st(platformFile, mimeType);
      } catch (e1) {
        print('⚠️ 0x0.st failed ($e1), trying catbox.moe...');
        try {
          downloadUrl = await _uploadToCatbox(platformFile, mimeType);
        } catch (e2) {
          throw Exception(
              'All upload services failed.\n0x0.st: $e1\ncatbox.moe: $e2');
        }
      }
      print('✅ Upload OK: $downloadUrl');

      final meta = {
        'id': fileId,
        'name': safeName,
        'originalName': platformFile.name,
        'type': _getFileType(platformFile.name),
        'status': 'ready',
        'mimeType': mimeType,
        'size': platformFile.size,
        'downloadUrl': downloadUrl,
        'uploaderId': uploaderId,
        'uploaderName': uploaderName,
        'meetingId': meetingId,
        'folderId': folderId,
        'downloadCount': 0,
        'viewCount': 0,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      };

      // Lưu Firestore bất đồng bộ (không block UI)
      _firestore.collection('files').doc(fileId).set(meta);

      return meta;
    } catch (e) {
      print('❌ Upload error: $e');
      rethrow;
    }
  }

  /// Upload lên transfer.sh bằng streaming (không OOM)
  Future<String> _uploadToTransferSh(
      PlatformFile pf, String safeName, String mimeType) async {
    final uri = Uri.parse('https://transfer.sh/$safeName');

    if (pf.path != null) {
      final file = File(pf.path!);
      final length = await file.length();
      final req = http.StreamedRequest('PUT', uri)
        ..headers['Max-Days'] = '365'
        ..headers['Content-Type'] = mimeType
        ..headers['Content-Length'] = length.toString();

      file.openRead().listen(
        req.sink.add,
        onDone: req.sink.close,
        onError: (e) => req.sink.addError(e),
      );

      final res = await req.send().timeout(const Duration(seconds: 60));
      final body = await res.stream.bytesToString();
      print('🔍 transfer.sh [${res.statusCode}] $body');
      if (res.statusCode != 200) {
        throw Exception('HTTP ${res.statusCode}: $body');
      }
      return body.trim();
    } else {
      final res = await http.put(uri,
          headers: {'Max-Days': '365', 'Content-Type': mimeType},
          body: pf.bytes).timeout(const Duration(seconds: 60));
      if (res.statusCode != 200) {
        throw Exception('HTTP ${res.statusCode}: ${res.body}');
      }
      return res.body.trim();
    }
  }

  /// Upload lên 0x0.st với User-Agent curl (tránh 403)
  Future<String> _uploadTo0x0st(PlatformFile pf, String mimeType) async {
    final request =
        http.MultipartRequest('POST', Uri.parse('https://0x0.st'));
    // 0x0.st yêu cầu User-Agent không phải browser
    request.headers['User-Agent'] = 'curl/7.88.1';

    if (pf.path != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'file', pf.path!,
        filename: pf.name,
      ));
    } else {
      request.files.add(http.MultipartFile.fromBytes(
        'file', pf.bytes!,
        filename: pf.name,
      ));
    }

    final res = await request.send().timeout(const Duration(seconds: 60));
    final body = await res.stream.bytesToString();
    print('🔍 0x0.st [${res.statusCode}] $body');
    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}: $body');
    }
    return body.trim();
  }

  /// Fallback: upload lên catbox.moe (anonymous, 200MB limit)
  Future<String> _uploadToCatbox(PlatformFile pf, String mimeType) async {
    final request = http.MultipartRequest(
        'POST', Uri.parse('https://catbox.moe/user/api.php'));
    request.headers['User-Agent'] = 'curl/7.88.1';
    request.fields['reqtype'] = 'fileupload';
    request.fields['userhash'] = ''; // anonymous

    if (pf.path != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'fileToUpload', pf.path!,
        filename: pf.name,
      ));
    } else {
      request.files.add(http.MultipartFile.fromBytes(
        'fileToUpload', pf.bytes!,
        filename: pf.name,
      ));
    }

    final res = await request.send().timeout(const Duration(seconds: 60));
    final body = await res.stream.bytesToString();
    print('🔍 catbox.moe [${res.statusCode}] $body');
    if (res.statusCode != 200 || !body.startsWith('https://')) {
      throw Exception('catbox.moe failed [${ res.statusCode}]: $body');
    }
    return body.trim();
  }

  Future<File?> downloadFile(Map<String, dynamic> fileData) async {
    try {
      _setLoading(true);
      final appDir = await getApplicationDocumentsDirectory();
      final dir = Directory('${appDir.path}/downloads');
      if (!await dir.exists()) await dir.create(recursive: true);

      final res =
          await http.get(Uri.parse(fileData['downloadUrl'] as String));
      if (res.statusCode != 200) {
        throw Exception('Download failed: ${res.statusCode}');
      }

      final localFile = File(
          '${dir.path}/${fileData['originalName'] ?? fileData['name']}');
      await localFile.writeAsBytes(res.bodyBytes);

      await _firestore
          .collection('files')
          .doc(fileData['id'])
          .update({
        'downloadCount': (fileData['downloadCount'] ?? 0) + 1,
        'lastAccessedAt': Timestamp.fromDate(DateTime.now()),
      });

      return localFile;
    } catch (e) {
      _setError('Lỗi tải file: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteFile(String fileId) async {
    try {
      _setLoading(true);
      await _firestore.collection('files').doc(fileId).delete();
      _files.removeWhere((f) => f['id'] == fileId);
      notifyListeners();
    } catch (e) {
      _setError('Lỗi xóa file: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<List<Map<String, dynamic>>> getFilesByMeeting(
      String meetingId) async {
    try {
      final snap = await _firestore
          .collection('files')
          .where('meetingId', isEqualTo: meetingId)
          .orderBy('createdAt', descending: true)
          .get();
      return snap.docs
          .map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>})
          .toList();
    } catch (e) {
      return [];
    }
  }

  String _getMimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    const map = {
      'pdf': 'application/pdf',
      'doc': 'application/msword',
      'docx':
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls': 'application/vnd.ms-excel',
      'xlsx':
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'ppt': 'application/vnd.ms-powerpoint',
      'pptx':
          'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'txt': 'text/plain',
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'mp4': 'video/mp4',
      'mp3': 'audio/mpeg',
      'zip': 'application/zip',
    };
    return map[ext] ?? 'application/octet-stream';
  }

  String _getFileType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)) return 'image';
    if (['mp4', 'mov', 'avi', 'mkv'].contains(ext)) return 'video';
    if (['mp3', 'wav', 'aac'].contains(ext)) return 'audio';
    if (['xls', 'xlsx', 'csv'].contains(ext)) return 'spreadsheet';
    if (['ppt', 'pptx'].contains(ext)) return 'presentation';
    if (['pdf', 'doc', 'docx', 'txt'].contains(ext)) return 'document';
    return 'other';
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  void _setError(String e) {
    _error = e;
    if (e.isNotEmpty) print('❌ Error: $e');
    notifyListeners();
  }

  void clearError() {
    _error = '';
    notifyListeners();
  }
}
