import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/meeting_model.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';

class MeetingProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<MeetingModel> _meetings = [];
  List<MeetingModel> _pendingMeetings = [];
  List<MeetingModel> _myMeetings = [];
  bool _isLoading = false;
  String? _error;

  List<MeetingModel> get meetings => _meetings;
  List<MeetingModel> get pendingMeetings => _pendingMeetings;
  List<MeetingModel> get myMeetings => _myMeetings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load tất cả cuộc họp (theo quyền)
  Future<void> loadMeetings(UserModel currentUser) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      Query query = _firestore.collection('meetings');

      // Lọc theo quyền
      if (currentUser.isSuperAdmin) {
        // Super Admin: xem tất cả
        query = query.orderBy('createdAt', descending: true);
      } else if (currentUser.isAdmin) {
        // Admin: xem cuộc họp của phòng ban
        query = query
            .where('departmentId', isEqualTo: currentUser.departmentId)
            .orderBy('createdAt', descending: true);
      } else if (currentUser.isManager) {
        // Manager: xem cuộc họp của team
        query = query.where('creatorId', whereIn: [
          currentUser.id,
          ...currentUser.teamIds
        ]).orderBy('createdAt', descending: true);
      } else {
        // Employee/Guest: chỉ xem cuộc họp của mình
        query = query
            .where('creatorId', isEqualTo: currentUser.id)
            .orderBy('createdAt', descending: true);
      }

      QuerySnapshot snapshot = await query.get();
      _meetings = snapshot.docs
          .map((doc) =>
              MeetingModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      // Load cuộc họp chờ phê duyệt
      await _loadPendingMeetings(currentUser);

      // Load cuộc họp của tôi
      await _loadMyMeetings(currentUser);
    } catch (e) {
      _error = 'Lỗi tải danh sách cuộc họp: $e';
      print('Error loading meetings: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load cuộc họp chờ phê duyệt
  Future<void> _loadPendingMeetings(UserModel currentUser) async {
    try {
      Query query = _firestore.collection('meetings').where('status',
          isEqualTo: MeetingStatus.pending.toString().split('.').last);

      if (currentUser.isSuperAdmin) {
        // Super Admin: xem tất cả cuộc họp chờ phê duyệt
      } else if (currentUser.isAdmin) {
        // Admin: xem cuộc họp chờ phê duyệt của phòng ban
        query =
            query.where('departmentId', isEqualTo: currentUser.departmentId);
      } else if (currentUser.isManager) {
        // Manager: xem cuộc họp chờ phê duyệt của team
        query = query.where('creatorId',
            whereIn: [currentUser.id, ...currentUser.teamIds]);
      } else {
        // Employee: chỉ xem cuộc họp chờ phê duyệt của mình
        query = query.where('creatorId', isEqualTo: currentUser.id);
      }

      QuerySnapshot snapshot = await query.get();
      _pendingMeetings = snapshot.docs
          .map((doc) =>
              MeetingModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('Error loading pending meetings: $e');
    }
  }

  // Load cuộc họp của tôi
  Future<void> _loadMyMeetings(UserModel currentUser) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('meetings')
          .where('creatorId', isEqualTo: currentUser.id)
          .orderBy('createdAt', descending: true)
          .get();

      _myMeetings = snapshot.docs
          .map((doc) =>
              MeetingModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('Error loading my meetings: $e');
    }
  }

  // Tạo cuộc họp mới
  Future<MeetingModel?> createMeeting(
      MeetingModel meeting, UserModel currentUser) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Kiểm tra quyền tạo cuộc họp
      if (!currentUser.canCreateMeeting(meeting.type)) {
        throw Exception('Bạn không có quyền tạo cuộc họp loại này');
      }

      // Kiểm tra xem có cần phê duyệt không
      MeetingStatus initialStatus = currentUser.needsApproval(meeting.type)
          ? MeetingStatus.pending
          : MeetingStatus.approved;

      // Tạo cuộc họp mới
      DocumentReference docRef = await _firestore.collection('meetings').add({
        ...meeting.toMap(),
        'status': initialStatus.toString().split('.').last,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Lấy cuộc họp vừa tạo
      DocumentSnapshot doc = await docRef.get();
      MeetingModel newMeeting =
          MeetingModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);

      // Thêm vào danh sách
      _meetings.insert(0, newMeeting);
      _myMeetings.insert(0, newMeeting);

      if (newMeeting.isPending) {
        _pendingMeetings.insert(0, newMeeting);
      }

      // Gửi thông báo phê duyệt nếu cần
      if (newMeeting.isPending) {
        await _sendApprovalNotification(newMeeting, currentUser);
      }

      return newMeeting;
    } catch (e) {
      _error = 'Lỗi tạo cuộc họp: $e';
      print('Error creating meeting: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cập nhật cuộc họp
  Future<bool> updateMeeting(
      MeetingModel meeting, UserModel currentUser) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Kiểm tra quyền chỉnh sửa
      if (meeting.creatorId != currentUser.id &&
          !currentUser.isSuperAdmin &&
          !currentUser.isAdmin) {
        throw Exception('Bạn không có quyền chỉnh sửa cuộc họp này');
      }

      // Cập nhật cuộc họp
      await _firestore.collection('meetings').doc(meeting.id).update({
        ...meeting.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Cập nhật trong danh sách
      int index = _meetings.indexWhere((m) => m.id == meeting.id);
      if (index != -1) {
        _meetings[index] = meeting;
      }

      int myIndex = _myMeetings.indexWhere((m) => m.id == meeting.id);
      if (myIndex != -1) {
        _myMeetings[myIndex] = meeting;
      }

      return true;
    } catch (e) {
      _error = 'Lỗi cập nhật cuộc họp: $e';
      print('Error updating meeting: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Xóa cuộc họp
  Future<bool> deleteMeeting(String meetingId, UserModel currentUser) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Tìm cuộc họp
      MeetingModel? meeting = _meetings.firstWhere((m) => m.id == meetingId);

      // Kiểm tra quyền xóa
      if (meeting.creatorId != currentUser.id &&
          !currentUser.isSuperAdmin &&
          !currentUser.isAdmin) {
        throw Exception('Bạn không có quyền xóa cuộc họp này');
      }

      // Xóa cuộc họp
      await _firestore.collection('meetings').doc(meetingId).delete();

      // Xóa khỏi danh sách
      _meetings.removeWhere((m) => m.id == meetingId);
      _myMeetings.removeWhere((m) => m.id == meetingId);
      _pendingMeetings.removeWhere((m) => m.id == meetingId);

      return true;
    } catch (e) {
      _error = 'Lỗi xóa cuộc họp: $e';
      print('Error deleting meeting: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Phê duyệt cuộc họp
  Future<bool> approveMeeting(String meetingId, UserModel approver,
      {String? notes}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Kiểm tra quyền phê duyệt
      if (!approver.hasPermission('approve_meetings') &&
          !approver.isSuperAdmin &&
          !approver.isAdmin &&
          !approver.isManager) {
        throw Exception('Bạn không có quyền phê duyệt cuộc họp');
      }

      // Cập nhật trạng thái
      await _firestore.collection('meetings').doc(meetingId).update({
        'status': MeetingStatus.approved.toString().split('.').last,
        'approverId': approver.id,
        'approverName': approver.displayName,
        'approvedAt': FieldValue.serverTimestamp(),
        'approvalNotes': notes,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Cập nhật trong danh sách
      int index = _meetings.indexWhere((m) => m.id == meetingId);
      if (index != -1) {
        MeetingModel updatedMeeting = _meetings[index].copyWith(
          status: MeetingStatus.approved,
          approverId: approver.id,
          approverName: approver.displayName,
          approvedAt: DateTime.now(),
          approvalNotes: notes,
          updatedAt: DateTime.now(),
        );
        _meetings[index] = updatedMeeting;
      }

      // Xóa khỏi danh sách chờ phê duyệt
      _pendingMeetings.removeWhere((m) => m.id == meetingId);

      // Gửi thông báo
      await _sendApprovalResultNotification(meetingId, true, notes);

      return true;
    } catch (e) {
      _error = 'Lỗi phê duyệt cuộc họp: $e';
      print('Error approving meeting: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Từ chối cuộc họp
  Future<bool> rejectMeeting(String meetingId, UserModel rejector,
      {required String reason}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Kiểm tra quyền từ chối
      if (!rejector.hasPermission('approve_meetings') &&
          !rejector.isSuperAdmin &&
          !rejector.isAdmin &&
          !rejector.isManager) {
        throw Exception('Bạn không có quyền từ chối cuộc họp');
      }

      // Cập nhật trạng thái
      await _firestore.collection('meetings').doc(meetingId).update({
        'status': MeetingStatus.rejected.toString().split('.').last,
        'approverId': rejector.id,
        'approverName': rejector.displayName,
        'approvedAt': FieldValue.serverTimestamp(),
        'approvalNotes': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Cập nhật trong danh sách
      int index = _meetings.indexWhere((m) => m.id == meetingId);
      if (index != -1) {
        MeetingModel updatedMeeting = _meetings[index].copyWith(
          status: MeetingStatus.rejected,
          approverId: rejector.id,
          approverName: rejector.displayName,
          approvedAt: DateTime.now(),
          approvalNotes: reason,
          updatedAt: DateTime.now(),
        );
        _meetings[index] = updatedMeeting;
      }

      // Xóa khỏi danh sách chờ phê duyệt
      _pendingMeetings.removeWhere((m) => m.id == meetingId);

      // Gửi thông báo
      await _sendApprovalResultNotification(meetingId, false, reason);

      return true;
    } catch (e) {
      _error = 'Lỗi từ chối cuộc họp: $e';
      print('Error rejecting meeting: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Hủy cuộc họp
  Future<bool> cancelMeeting(String meetingId, UserModel currentUser,
      {String? reason}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Tìm cuộc họp
      MeetingModel? meeting = _meetings.firstWhere((m) => m.id == meetingId);

      // Kiểm tra quyền hủy
      if (meeting.creatorId != currentUser.id &&
          !currentUser.isSuperAdmin &&
          !currentUser.isAdmin) {
        throw Exception('Bạn không có quyền hủy cuộc họp này');
      }

      // Cập nhật trạng thái
      await _firestore.collection('meetings').doc(meetingId).update({
        'status': MeetingStatus.cancelled.toString().split('.').last,
        'approvalNotes': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Cập nhật trong danh sách
      int index = _meetings.indexWhere((m) => m.id == meetingId);
      if (index != -1) {
        MeetingModel updatedMeeting = _meetings[index].copyWith(
          status: MeetingStatus.cancelled,
          approvalNotes: reason,
          updatedAt: DateTime.now(),
        );
        _meetings[index] = updatedMeeting;
      }

      // Xóa khỏi danh sách chờ phê duyệt nếu có
      _pendingMeetings.removeWhere((m) => m.id == meetingId);

      return true;
    } catch (e) {
      _error = 'Lỗi hủy cuộc họp: $e';
      print('Error cancelling meeting: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Gửi thông báo phê duyệt
  Future<void> _sendApprovalNotification(
      MeetingModel meeting, UserModel creator) async {
    try {
      // Tìm người phê duyệt
      List<UserModel> approvers = await _getApprovers(creator);

      for (UserModel approver in approvers) {
        await _firestore.collection('notifications').add({
          'userId': approver.id,
          'title': 'Cuộc họp cần phê duyệt',
          'message': 'Cuộc họp "${meeting.title}" cần được phê duyệt',
          'type': 'meeting_approval',
          'meetingId': meeting.id,
          'createdAt': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      }
    } catch (e) {
      print('Error sending approval notification: $e');
    }
  }

  // Gửi thông báo kết quả phê duyệt
  Future<void> _sendApprovalResultNotification(
      String meetingId, bool approved, String? notes) async {
    try {
      MeetingModel? meeting = _meetings.firstWhere((m) => m.id == meetingId);

      String title =
          approved ? 'Cuộc họp đã được phê duyệt' : 'Cuộc họp bị từ chối';
      String message = approved
          ? 'Cuộc họp "${meeting.title}" đã được phê duyệt'
          : 'Cuộc họp "${meeting.title}" bị từ chối: $notes';

      await _firestore.collection('notifications').add({
        'userId': meeting.creatorId,
        'title': title,
        'message': message,
        'type': 'meeting_approval_result',
        'meetingId': meetingId,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    } catch (e) {
      print('Error sending approval result notification: $e');
    }
  }

  // Lấy danh sách người phê duyệt
  Future<List<UserModel>> _getApprovers(UserModel creator) async {
    try {
      List<UserModel> approvers = [];

      if (creator.isEmployee) {
        // Employee: Manager phê duyệt
        if (creator.managerId != null) {
          DocumentSnapshot managerDoc = await _firestore
              .collection('users')
              .doc(creator.managerId!)
              .get();
          if (managerDoc.exists) {
            approvers.add(UserModel.fromMap(
                managerDoc.data() as Map<String, dynamic>, managerDoc.id));
          }
        }
      } else if (creator.isManager) {
        // Manager: Admin phê duyệt
        QuerySnapshot adminSnapshot = await _firestore
            .collection('users')
            .where('role', isEqualTo: UserRole.admin.toString().split('.').last)
            .where('departmentId', isEqualTo: creator.departmentId)
            .get();

        approvers.addAll(adminSnapshot.docs.map((doc) =>
            UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)));
      }

      return approvers;
    } catch (e) {
      print('Error getting approvers: $e');
      return [];
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
