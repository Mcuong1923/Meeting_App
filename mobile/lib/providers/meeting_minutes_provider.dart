import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/meeting_minutes_model.dart';

class MeetingMinutesProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  String? _error;
  List<MeetingMinutesModel> _minutesVersions = [];
  MeetingMinutesModel? _currentVersion;

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<MeetingMinutesModel> get minutesVersions => _minutesVersions;
  MeetingMinutesModel? get currentVersion => _currentVersion;

  /// Get latest minute version for meeting detail screen
  Future<MeetingMinutesModel?> getLatestMinute(String meetingId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Query: meetingId + orderBy updatedAt desc + limit 1
      final snapshot = await _firestore
          .collection('meeting_minutes')
          .where('meetingId', isEqualTo: meetingId)
          .orderBy('updatedAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        _currentVersion = null;
        _isLoading = false;
        notifyListeners();
        return null;
      }

      final minute = MeetingMinutesModel.fromMap(snapshot.docs.first.data(), snapshot.docs.first.id);
      _currentVersion = minute;
      
      _isLoading = false;
      notifyListeners();
      return minute;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      debugPrint('Error fetching latest minute: $e');
      if (e.toString().contains('failed-precondition')) {
        debugPrint('NEED INDEX: Check log for URL to create index');
      }
      return null;
    }
  }

  /// Get all minutes versions for a meeting (History)
  Future<List<MeetingMinutesModel>> getMinutesForMeeting(String meetingId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final snapshot = await _firestore
          .collection('meeting_minutes')
          .where('meetingId', isEqualTo: meetingId)
          .orderBy('versionNumber', descending: true)
          .get();

      _minutesVersions = snapshot.docs
          .map((doc) => MeetingMinutesModel.fromMap(doc.data(), doc.id))
          .toList();

      _isLoading = false;
      notifyListeners();
      return _minutesVersions;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      debugPrint('Error fetching history: $e');
      return [];
    }
  }

  /// Get the current/latest version for display
  MeetingMinutesModel? getCurrentVersion(String meetingId) {
    if (_minutesVersions.isEmpty) return null;
    
    // Try to find latest approved first
    final approved = _minutesVersions
        .where((m) => m.isApproved)
        .toList();
    if (approved.isNotEmpty) return approved.first;
    
    // Otherwise return latest version
    return _minutesVersions.first;
  }

  /// Create new meeting minutes (first version)
  Future<MeetingMinutesModel?> createMeetingMinutes({
    required String meetingId,
    required String title,
    required String content,
    required String createdBy,
    required String createdByName,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final now = DateTime.now();
      final docRef = await _firestore.collection('meeting_minutes').add({
        'meetingId': meetingId,
        'title': title,
        'content': content,
        'versionNumber': 1,
        'status': MinutesStatus.draft.name,
        'createdBy': createdBy,
        'createdByName': createdByName,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedBy': createdBy,
        'updatedByName': createdByName,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final newMinutes = MeetingMinutesModel(
        id: docRef.id,
        meetingId: meetingId,
        title: title,
        content: content,
        versionNumber: 1,
        status: MinutesStatus.draft,
        createdBy: createdBy,
        createdByName: createdByName,
        createdAt: now,
        updatedBy: createdBy,
        updatedByName: createdByName,
        updatedAt: now,
      );

      _minutesVersions.insert(0, newMinutes);
      _currentVersion = newMinutes;

      _isLoading = false;
      notifyListeners();
      return newMinutes;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      debugPrint('Error creating meeting minutes: $e');
      return null;
    }
  }

  /// Upsert Draft (Create if new, Update if exists)
  /// Returns minute ID if successful, null otherwise
  Future<String?> upsertDraft({
    String? minutesId,
    required String meetingId,
    required String title,
    required String content,
    required String userId,
    required String userName,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final now = DateTime.now();
      String docId = minutesId ?? '';

      if (minutesId != null && minutesId.isNotEmpty) {
        // UPDATE existing draft
        await _firestore.collection('meeting_minutes').doc(minutesId).update({
          'title': title,
          'content': content,
          'updatedBy': userId,
          'updatedByName': userName,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        docId = minutesId;
      } else {
        // CREATE new draft
        // Need to determine version number? For MVP, assume 1 if no history check, 
        // or just let backend/client decide. Here we just set 1 for simplicity of 'upsert' context 
        // usually being the start. If proper versioning needed, use createNewVersion.
        // But requested flow is simple save draft.
        
        // Check if there are existing minutes to increment version? 
        // For simplicity, we'll start at 1. If strict versioning needed, separate Create methods are better.
        // Assuming this is "Current working draft".
        
        final docRef = await _firestore.collection('meeting_minutes').add({
          'meetingId': meetingId,
          'title': title,
          'content': content,
          'versionNumber': 1, // Default start
          'status': MinutesStatus.draft.name,
          'createdBy': userId,
          'createdByName': userName,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedBy': userId,
          'updatedByName': userName,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        docId = docRef.id;
      }

      // Reload latest to update cache
      await getLatestMinute(meetingId);

      _isLoading = false;
      notifyListeners();
      return docId;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      debugPrint('Error upserting draft: $e');
      return null;
    }
  }

  /// Create new version (snapshot)
  Future<MeetingMinutesModel?> createNewVersion({
    required String meetingId,
    required String title,
    required String content,
    required String createdBy,
    required String createdByName,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Get next version number
      final maxVersion = _minutesVersions.isNotEmpty
          ? _minutesVersions.map((m) => m.versionNumber).reduce((a, b) => a > b ? a : b)
          : 0;
      final newVersionNumber = maxVersion + 1;

      final now = DateTime.now();
      final docRef = await _firestore.collection('meeting_minutes').add({
        'meetingId': meetingId,
        'title': title,
        'content': content,
        'versionNumber': newVersionNumber,
        'status': MinutesStatus.draft.name,
        'createdBy': createdBy,
        'createdByName': createdByName,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedBy': createdBy,
        'updatedByName': createdByName,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final newMinutes = MeetingMinutesModel(
        id: docRef.id,
        meetingId: meetingId,
        title: title,
        content: content,
        versionNumber: newVersionNumber,
        status: MinutesStatus.draft,
        createdBy: createdBy,
        createdByName: createdByName,
        createdAt: now,
        updatedBy: createdBy,
        updatedByName: createdByName,
        updatedAt: now,
      );

      _minutesVersions.insert(0, newMinutes);
      _currentVersion = newMinutes;

      _isLoading = false;
      notifyListeners();
      return newMinutes;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      debugPrint('Error creating new version: $e');
      return null;
    }
  }

  /// Submit for approval
  Future<bool> submitForApproval({
    required String minutesId,
    required bool isAdmin,
    String? note,
    String? userId, // Required if isAdmin is true for auto-approve
    String? userName,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final Map<String, dynamic> updates = {};
      
      if (isAdmin) {
        // Admin auto-approves
        updates['status'] = MinutesStatus.approved.name;
        updates['approvedBy'] = userId;
        updates['approvedByName'] = userName;
        updates['approvedAt'] = FieldValue.serverTimestamp();
        updates['approvalComment'] = 'Auto-approved by Admin';
      } else {
        // Normal submission
        updates['status'] = MinutesStatus.pending_approval.name;
        updates['submissionNote'] = note;
        updates['submittedAt'] = FieldValue.serverTimestamp();
      }
      
      updates['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore.collection('meeting_minutes').doc(minutesId).update(updates);

      // Refresh data
      if (_currentVersion != null) {
        await getLatestMinute(_currentVersion!.meetingId);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      debugPrint('Error submitting minutes for approval: $e');
      return false;
    }
  }

  /// Approve minutes (Admin/Chair only)
  Future<bool> approveMinutes({
    required String minutesId,
    required String approvedBy,
    required String approvedByName,
    String? comment,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firestore.collection('meeting_minutes').doc(minutesId).update({
        'status': MinutesStatus.approved.name,
        'approvedBy': approvedBy,
        'approvedByName': approvedByName,
        'approvedAt': FieldValue.serverTimestamp(),
        'approvalComment': comment,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update local cache
      final index = _minutesVersions.indexWhere((m) => m.id == minutesId);
      if (index != -1) {
        _minutesVersions[index] = _minutesVersions[index].copyWith(
          status: MinutesStatus.approved,
          approvedBy: approvedBy,
          approvedByName: approvedByName,
          approvedAt: DateTime.now(),
          approvalComment: comment,
          updatedAt: DateTime.now(),
        );
        if (_currentVersion?.id == minutesId) {
          _currentVersion = _minutesVersions[index];
        }
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      debugPrint('Error approving minutes: $e');
      return false;
    }
  }

  /// Reject minutes
  Future<bool> rejectMinutes({
    required String minutesId,
    required String rejectedBy,
    required String rejectedByName,
    required String reason,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firestore.collection('meeting_minutes').doc(minutesId).update({
        'status': MinutesStatus.rejected.name,
        'rejectedBy': rejectedBy,
        'rejectedByName': rejectedByName,
        'rejectionReason': reason,
        'rejectedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update local cache
      final index = _minutesVersions.indexWhere((m) => m.id == minutesId);
      if (index != -1) {
        _minutesVersions[index] = _minutesVersions[index].copyWith(
          status: MinutesStatus.rejected,
          rejectedBy: rejectedBy,
          rejectedByName: rejectedByName,
          rejectionReason: reason,
          rejectedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        if (_currentVersion?.id == minutesId) {
          _currentVersion = _minutesVersions[index];
        }
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      debugPrint('Error rejecting minutes: $e');
      return false;
    }
  }

  /// Delete version (only DRAFT allowed)
  Future<bool> deleteVersion(String minutesId) async {
    try {
      // Check if version is draft
      final version = _minutesVersions.firstWhere(
        (m) => m.id == minutesId,
        orElse: () => throw Exception('Version not found'),
      );

      if (!version.canDelete) {
        _error = 'Chỉ có thể xóa biên bản nháp';
        notifyListeners();
        return false;
      }

      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firestore.collection('meeting_minutes').doc(minutesId).delete();

      // Update local cache
      _minutesVersions.removeWhere((m) => m.id == minutesId);
      if (_currentVersion?.id == minutesId) {
        _currentVersion = _minutesVersions.isNotEmpty ? _minutesVersions.first : null;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      debugPrint('Error deleting version: $e');
      return false;
    }
  }

  List<MeetingMinutesModel> _allMinutes = [];
  List<MeetingMinutesModel> get allMinutes => _allMinutes;

  /// Get all minutes for archive screen (APPROVED ONLY)
  Future<List<MeetingMinutesModel>> getAllMinutes({
    String? userId,
    bool isGlobalAdmin = false,
    bool showArchived = false,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Force APPROVED status filter (Global Menu shows ONLY Approved)
      Query query = _firestore.collection('meeting_minutes')
          .where('status', isEqualTo: MinutesStatus.approved.name);
      
      // Archive filter
      if (!showArchived) {
        query = query.where('isArchived', isEqualTo: false);
      } else {
        query = query.where('isArchived', isEqualTo: true);
      }

      // Sort by approved date or updated date desc
      query = query.orderBy('approvedAt', descending: true);

      final snapshot = await query.get();

      final allDocs = snapshot.docs
          .map((doc) => MeetingMinutesModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      if (isGlobalAdmin) {
        _allMinutes = allDocs;
      } else {
        // Filter for regular users (only approved minutes they can see)
        // Note: Firestore rules will enforce. Here we just apply basic filter.
        _allMinutes = allDocs;
      }

      _isLoading = false;
      notifyListeners();
      return _allMinutes;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      debugPrint('Error fetching all minutes: $e');
      if (e.toString().contains('failed-precondition')) {
        debugPrint('NEED INDEX: Check log for URL to create composite index');
      }
      return [];
    }
  }

  /// Archive minutes (Admin or Secretary) - IMMEDIATE
  Future<bool> archiveMinutes({
    required String minutesId,
    required String archivedBy,
    required String archivedByName,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firestore.collection('meeting_minutes').doc(minutesId).update({
        'isArchived': true,
        'archivedAt': FieldValue.serverTimestamp(),
        'archivedBy': archivedBy,
        'archivedByName': archivedByName,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update local cache
      final index = _minutesVersions.indexWhere((m) => m.id == minutesId);
      if (index != -1) {
        _minutesVersions[index] = _minutesVersions[index].copyWith(
          isArchived: true,
          archivedAt: DateTime.now(),
          archivedBy: archivedBy,
          archivedByName: archivedByName,
        );
        if (_currentVersion?.id == minutesId) {
          _currentVersion = _minutesVersions[index];
        }
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      debugPrint('Error archiving minutes: $e');
      return false;
    }
  }

  /// Unarchive minutes (Admin or Secretary)
  Future<bool> unarchiveMinutes(String minutesId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firestore.collection('meeting_minutes').doc(minutesId).update({
        'isArchived': false,
        'archivedAt': null,
        'archivedBy': null,
        'archivedByName': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update local cache
      final index = _minutesVersions.indexWhere((m) => m.id == minutesId);
      if (index != -1) {
        _minutesVersions[index] = _minutesVersions[index].copyWith(
          isArchived: false,
          archivedAt: null,
          archivedBy: null,
          archivedByName: null,
        );
        if (_currentVersion?.id == minutesId) {
          _currentVersion = _minutesVersions[index];
        }
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      debugPrint('Error unarchiving minutes: $e');
      return false;
    }
  }



  void clearCache() {
    _minutesVersions = [];
    _allMinutes = [];
    _currentVersion = null;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
