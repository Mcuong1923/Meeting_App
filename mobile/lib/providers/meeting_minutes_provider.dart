import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MeetingMinutesProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> createMeetingMinutes({
    required String meetingId,
    required String content,
    required String createdBy,
    required String createdByName,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firestore.collection('meeting_minutes').add({
        'meetingId': meetingId,
        'content': content,
        'createdBy': createdBy,
        'createdByName': createdByName,
        'status': 'draft',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      debugPrint('Error creating meeting minutes: $e');
    }
  }

  Future<void> updateMeetingMinutes({
    required String minutesId,
    required String content,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firestore.collection('meeting_minutes').doc(minutesId).update({
        'content': content,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      debugPrint('Error updating meeting minutes: $e');
    }
  }

  Future<void> submitForApproval(String minutesId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firestore.collection('meeting_minutes').doc(minutesId).update({
        'status': 'pending_approval',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      debugPrint('Error submitting minutes for approval: $e');
    }
  }

  Future<void> approveMinutes({
    required String minutesId,
    required String approvedBy,
    required String approvedByName,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firestore.collection('meeting_minutes').doc(minutesId).update({
        'status': 'approved',
        'approvedBy': approvedBy,
        'approvedByName': approvedByName,
        'approvedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      debugPrint('Error approving minutes: $e');
    }
  }

  Future<void> rejectMinutes({
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
        'status': 'rejected',
        'rejectedBy': rejectedBy,
        'rejectedByName': rejectedByName,
        'rejectionReason': reason,
        'rejectedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      debugPrint('Error rejecting minutes: $e');
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
