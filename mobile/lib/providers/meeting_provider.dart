import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/meeting_model.dart';
import '../models/user_model.dart';
import '../models/user_role.dart' hide MeetingStatus;
import '../models/meeting_decision_model.dart';
import '../models/meeting_task_model.dart';
import '../models/notification_model.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';

class MeetingProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<MeetingModel> _meetings = [];
  List<MeetingModel> _pendingMeetings = [];
  List<MeetingModel> _myMeetings = [];
  List<MeetingDecision> _decisions = []; // Current meeting decisions
  List<MeetingTask> _tasks = []; // Current meeting tasks
  bool _isLoading = false;
  String? _error;
  
  // Debug: Track request tokens and active meetingId
  int _loadDecisionsToken = 0;
  int _loadTasksToken = 0;
  String? _activeMeetingId;

  List<MeetingModel> get meetings => _meetings;
  List<MeetingModel> get pendingMeetings => _pendingMeetings;
  List<MeetingModel> get myMeetings => _myMeetings;
  List<MeetingDecision> get decisions => _decisions;
  List<MeetingTask> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Get tasks filtered by meetingId
  List<MeetingTask> getTasksForMeeting(String meetingId) {
    return _tasks.where((task) => task.meetingId == meetingId).toList();
  }
  String get providerHash => hashCode.toRadixString(16);

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
  Future<MeetingModel?> createMeeting(MeetingModel meeting,
      UserModel currentUser, NotificationProvider? notificationProvider) async {
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
        await _sendApprovalRequestToAdmins(newMeeting, notificationProvider);
      }

      // Gửi notifications dựa trên approval status
      print('🔄 MeetingProvider: Attempting to send notifications...');
      print('🔄 NotificationProvider is null: ${notificationProvider == null}');
      print('🔄 Meeting status: ${newMeeting.status}, approvalStatus: ${newMeeting.approvalStatus}');

      if (notificationProvider != null) {
        try {
          // Chỉ gửi invitation cho meeting đã được approve (admin tạo)
          if (newMeeting.approvalStatus == MeetingApprovalStatus.auto_approved ||
              newMeeting.approvalStatus == MeetingApprovalStatus.approved) {
            print('🔄 Sending participant invitations for auto-approved meeting...');
            await _sendParticipantInvitations(newMeeting, notificationProvider);
            print('✅ Participant invitations sent');
          } else {
            print('ℹ️ Meeting pending approval, skipping participant notifications');
          }
        } catch (e) {
          print('❌ Error sending meeting notifications: $e');
        }
      } else {
        print('❌ NotificationProvider is null!');
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
      {String? notes, NotificationProvider? notificationProvider}) async {
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

      // Fetch meeting to check current status
      DocumentSnapshot doc = await _firestore.collection('meetings').doc(meetingId).get();
      if (!doc.exists) throw Exception('Meeting not found');

      MeetingModel meeting = MeetingModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);

      // Guard: Prevent duplicate approvals
      if (meeting.approvalStatus == MeetingApprovalStatus.approved ||
          meeting.approvalStatus == MeetingApprovalStatus.auto_approved) {
        print('⚠️ Meeting already approved, skipping notification');
        return false;
      }

      // Cập nhật trạng thái
      await _firestore.collection('meetings').doc(meetingId).update({
        'status': MeetingStatus.approved.toString().split('.').last,
        'approvalStatus': MeetingApprovalStatus.approved.toString().split('.').last,
        'approverId': approver.id,
        'approverName': approver.displayName,
        'approvedBy': approver.id,
        'approvedAt': FieldValue.serverTimestamp(),
        'approvalNotes': notes,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Fetch updated meeting
      DocumentSnapshot updatedDoc = await _firestore.collection('meetings').doc(meetingId).get();
      MeetingModel approvedMeeting = MeetingModel.fromMap(
        updatedDoc.data() as Map<String, dynamic>,
        updatedDoc.id,
      );

      // Cập nhật trong danh sách
      int index = _meetings.indexWhere((m) => m.id == meetingId);
      if (index != -1) {
        _meetings[index] = approvedMeeting;
      }

      // Xóa khỏi danh sách chờ phê duyệt
      _pendingMeetings.removeWhere((m) => m.id == meetingId);

      // Gửi thông báo
      if (notificationProvider != null) {
        // 1. Notify creator
        await notificationProvider.createNotification(
          NotificationTemplate.meetingApproved(
            userId: meeting.creatorId,
            meetingTitle: meeting.title,
            meetingId: meeting.id,
            approverName: approver.displayName,
          ),
        );

        // 2. Send invitations to ALL participants
        await _sendParticipantInvitations(approvedMeeting, notificationProvider);
      }

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
      {required String reason, NotificationProvider? notificationProvider}) async {
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

      // Fetch meeting
      DocumentSnapshot doc = await _firestore.collection('meetings').doc(meetingId).get();
      if (!doc.exists) throw Exception('Meeting not found');

      MeetingModel meeting = MeetingModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);

      // Cập nhật trạng thái
      await _firestore.collection('meetings').doc(meetingId).update({
        'status': MeetingStatus.rejected.toString().split('.').last,
        'approvalStatus': MeetingApprovalStatus.rejected.toString().split('.').last,
        'rejectedBy': rejector.id,
        'rejectedAt': FieldValue.serverTimestamp(),
        'rejectedReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Fetch updated meeting
      DocumentSnapshot updatedDoc = await _firestore.collection('meetings').doc(meetingId).get();
      MeetingModel rejectedMeeting = MeetingModel.fromMap(
        updatedDoc.data() as Map<String, dynamic>,
        updatedDoc.id,
      );

      // Cập nhật trong danh sách
      int index = _meetings.indexWhere((m) => m.id == meetingId);
      if (index != -1) {
        _meetings[index] = rejectedMeeting;
      }

      // Xóa khỏi danh sách chờ phê duyệt
      _pendingMeetings.removeWhere((m) => m.id == meetingId);

      // Gửi thông báo cho creator
      if (notificationProvider != null) {
        await notificationProvider.createNotification(
          NotificationTemplate.meetingRejected(
            userId: meeting.creatorId,
            meetingTitle: meeting.title,
            meetingId: meeting.id,
            rejectorName: rejector.displayName,
            reason: reason,
          ),
        );
      }

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

  // --- Decisions Management ---

  // Load decisions for a meeting
  Future<void> loadDecisions(String meetingId) async {
    final token = ++_loadDecisionsToken;
    final now = DateTime.now().toIso8601String();
    
    print('[DECISION][LOAD][START] meetingId=$meetingId token=$token time=$now');
    
    try {
      // Clear old decisions immediately to prevent stale data flash
      _decisions = [];
      _activeMeetingId = meetingId;
      _isLoading = true;
      _error = null;
      print('[DECISION][LOAD][CLEAR] meetingId=$meetingId token=$token clearedList=true');
      notifyListeners();

      final queryPath = 'decisions where meetingId==$meetingId';
      print('[DECISION][LOAD][QUERY] meetingId=$meetingId token=$token path="$queryPath"');
      
      QuerySnapshot snapshot = await _firestore
          .collection('decisions')
          .where('meetingId', isEqualTo: meetingId)
          .orderBy('createdAt', descending: true)
          .get();

      final docIds = snapshot.docs.take(3).map((d) => d.id).toList();
      print('[DECISION][LOAD][RESULT] meetingId=$meetingId token=$token count=${snapshot.docs.length} docIds=$docIds');
      
      // Check if this is still the active request
      if (_activeMeetingId == meetingId && token == _loadDecisionsToken) {
        _decisions = snapshot.docs
            .map((doc) => MeetingDecision.fromMap(
                doc.data() as Map<String, dynamic>, doc.id))
            .toList();
        print('[DECISION][LOAD][APPLY] meetingId=$meetingId token=$token applied=true activeMeetingId=$_activeMeetingId');
        
        // DB verification
        print('[DECISION][DB_CHECK] meetingId=$meetingId countFromDB=${snapshot.docs.length} time=${DateTime.now().toIso8601String()}');
      } else {
        print('[DECISION][LOAD][DISCARD] meetingId=$meetingId token=$token reason="stale token" activeToken=$_loadDecisionsToken activeMeetingId=$_activeMeetingId');
      }
    } catch (e) {
      _error = 'Lỗi tải quyết định: $e';
      print('[DECISION][LOAD][ERROR] meetingId=$meetingId token=$token error=$e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add a new decision
  Future<bool> addDecision(MeetingDecision decision) async {
    final now = DateTime.now().toIso8601String();
    final collectionPath = 'decisions';
    
    print('[DECISION][CREATE][START] meetingId=${decision.meetingId} path="$collectionPath" payloadMeetingId=${decision.meetingId} by=${decision.createdBy} time=$now');
    
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Create new decision in Firestore
      DocumentReference docRef = await _firestore.collection('decisions').add({
        ...decision.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('[DECISION][CREATE][SUCCESS] meetingId=${decision.meetingId} docId=${docRef.id} path="$collectionPath/${docRef.id}"');

      // Create a local copy with the new ID for immediate UI update
      MeetingDecision newDecision = decision.copyWith(id: docRef.id);
      
      // Update local list
      _decisions.insert(0, newDecision);
      
      // DB verification
      final verifySnapshot = await _firestore
          .collection('decisions')
          .where('meetingId', isEqualTo: decision.meetingId)
          .get();
      print('[DECISION][DB_CHECK] meetingId=${decision.meetingId} countFromDB=${verifySnapshot.docs.length} time=${DateTime.now().toIso8601String()}');
      
      return true;
    } catch (e) {
      _error = 'Lỗi thêm quyết định: $e';
      print('[DECISION][CREATE][ERROR] meetingId=${decision.meetingId} error=$e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update a decision
  Future<bool> updateDecision(MeetingDecision decision) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firestore.collection('decisions').doc(decision.id).update({
        ...decision.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update local list
      int index = _decisions.indexWhere((d) => d.id == decision.id);
      if (index != -1) {
        _decisions[index] = decision;
      }
      
      return true;
    } catch (e) {
      _error = 'Lỗi cập nhật quyết định: $e';
      print('Error updating decision: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete a decision
  Future<bool> deleteDecision(String decisionId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firestore.collection('decisions').doc(decisionId).delete();

      // Update local list
      _decisions.removeWhere((d) => d.id == decisionId);
      
      return true;
    } catch (e) {
      _error = 'Lỗi xóa quyết định: $e';
      print('Error deleting decision: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear decisions
  void clearDecisions() {
    _decisions = [];
    notifyListeners();
  }

  // --- Tasks Management ---

  // Load tasks for a meeting
  Future<void> loadTasks(String meetingId) async {
    final token = ++_loadTasksToken;
    final now = DateTime.now().toIso8601String();
    
    print('[TASK][LOAD][START] meetingId=$meetingId token=$token time=$now');
    
    try {
      // Clear old tasks immediately to prevent stale data flash
      _tasks = [];
      _activeMeetingId = meetingId;
      _isLoading = true;
      _error = null;
      print('[TASK][LOAD][CLEAR] meetingId=$meetingId token=$token clearedList=true');
      notifyListeners();

      final queryPath = 'tasks where meetingId==$meetingId';
      print('[TASK][LOAD][QUERY] meetingId=$meetingId token=$token path="$queryPath"');
      
      QuerySnapshot snapshot = await _firestore
          .collection('tasks')
          .where('meetingId', isEqualTo: meetingId)
          .orderBy('createdAt', descending: true)
          .get();

      final docIds = snapshot.docs.take(3).map((d) => d.id).toList();
      print('[TASK][LOAD][RESULT] meetingId=$meetingId token=$token count=${snapshot.docs.length} docIds=$docIds');
      
      // Check if this is still the active request
      if (_activeMeetingId == meetingId && token == _loadTasksToken) {
        _tasks = snapshot.docs
            .map((doc) => MeetingTask.fromMap(
                doc.data() as Map<String, dynamic>, doc.id))
            .toList();
        print('[TASK][LOAD][APPLY] meetingId=$meetingId token=$token applied=true activeMeetingId=$_activeMeetingId');
        
        // DB verification
        print('[TASK][DB_CHECK] meetingId=$meetingId countFromDB=${snapshot.docs.length} time=${DateTime.now().toIso8601String()}');
      } else {
        print('[TASK][LOAD][DISCARD] meetingId=$meetingId token=$token reason="stale token" activeToken=$_loadTasksToken activeMeetingId=$_activeMeetingId');
      }
    } catch (e) {
      _error = 'Lỗi tải nhiệm vụ: $e';
      print('[TASK][LOAD][ERROR] meetingId=$meetingId token=$token error=$e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add a new task (returns docId on success, null on failure)
  Future<String?> addTask(MeetingTask task) async {
    final now = DateTime.now().toIso8601String();
    final collectionPath = 'tasks';
    
    print('[TASK][CREATE][START] meetingId=${task.meetingId} path="$collectionPath" payloadMeetingId=${task.meetingId} by=${task.createdBy} time=$now');
    
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Create new task in Firestore
      DocumentReference docRef = await _firestore.collection('tasks').add({
        ...task.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('[TASK][CREATE][SUCCESS] meetingId=${task.meetingId} docId=${docRef.id} path="$collectionPath/${docRef.id}"');

      // READBACK - Verify persistence
      DocumentSnapshot createdDoc = await docRef.get();
      if (createdDoc.exists) {
        final data = createdDoc.data() as Map<String, dynamic>;
        print('[TASK][CREATE][READBACK] docId=${docRef.id} meetingId=${data['meetingId']} status=${data['status']} createdAt=${data['createdAt']}');
      } else {
        print('[TASK][CREATE][READBACK] ERROR: Document not found immediately after create!');
      }

      // Create a local copy with the new ID for immediate UI update
      MeetingTask newTask = task.copyWith(id: docRef.id);
      
      // Update local list
      _tasks.insert(0, newTask);
      
      // DB verification (Count check)
      final verifySnapshot = await _firestore
          .collection('tasks')
          .where('meetingId', isEqualTo: task.meetingId)
          .get();
      print('[TASK][DB_CHECK] meetingId=${task.meetingId} countFromDB=${verifySnapshot.docs.length} time=${DateTime.now().toIso8601String()}');
      
      return docRef.id; // Return document ID on success
    } catch (e) {
      _error = 'Lỗi thêm nhiệm vụ: $e';
      print('[TASK][CREATE][ERROR] meetingId=${task.meetingId} error=$e');
      return null; // Return null on failure
    } finally {
      notifyListeners();
    }
  }

  // Update a task
  Future<bool> updateTask(MeetingTask task) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print('[TASK][UPDATE][START] taskId=${task.id} status=${task.status} meetingId=${task.meetingId}');

      await _firestore.collection('tasks').doc(task.id).update({
        ...task.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update local list
      int index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = task;
        print('[TASK][UPDATE][SUCCESS] Updated local task index=$index');
      }
      
      return true;
    } catch (e) {
      _error = 'Lỗi cập nhật nhiệm vụ: $e';
      print('[TASK][UPDATE][ERROR] taskId=${task.id} error=$e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete a task
  Future<bool> deleteTask(String taskId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      print('[TASK][DELETE][START] taskId=$taskId');

      await _firestore.collection('tasks').doc(taskId).delete();

      // Update local list
      _tasks.removeWhere((t) => t.id == taskId);
      print('[TASK][DELETE][SUCCESS] Removed from local list');
      
      return true;
    } catch (e) {
      _error = 'Lỗi xóa nhiệm vụ: $e';
      print('[TASK][DELETE][ERROR] taskId=$taskId error=$e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== Helper Methods (Fix for Bug A) ====================

  /// Fetch meeting directly from Firestore (bypassing local list/filtering)
  /// Includes auto-migration for pending participants on approved meetings
  Future<MeetingModel?> getMeetingById(String meetingId) async {
    try {
      print('🔍 Fetching meeting directly: $meetingId');
      final doc = await _firestore.collection('meetings').doc(meetingId).get();
      
      if (!doc.exists) {
        print('❌ Meeting not found: $meetingId');
        return null;
      }
      
      print('✅ Meeting found: $meetingId (Status: ${doc.data()?['status']})');
      MeetingModel meeting = MeetingModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      
      // Auto-migrate pending participants if meeting is approved
      meeting = await _autoMigratePendingParticipants(meeting);
      
      return meeting;
    } catch (e) {
      print('❌ Error fetching meetingById: $e');
      return null;
    }
  }

  /// Auto-migrate pending participants to accepted for approved meetings
  Future<MeetingModel> _autoMigratePendingParticipants(MeetingModel meeting) async {
    // Only migrate if meeting is approved
    if (meeting.status != MeetingStatus.approved && 
        meeting.approvalStatus != MeetingApprovalStatus.approved &&
        meeting.approvalStatus != MeetingApprovalStatus.auto_approved) {
      return meeting;
    }

    // Check if any participants need migration (hasConfirmed == false)
    final pendingParticipants = meeting.participants.where((p) => !p.hasConfirmed).toList();
    
    if (pendingParticipants.isEmpty) {
      print('[PARTICIPANT][MIGRATE] meetingId=${meeting.id} no pending participants');
      return meeting;
    }

    print('[PARTICIPANT][MIGRATE] meetingId=${meeting.id} pending->accepted count=${pendingParticipants.length}');
    
    try {
      // Create migrated participants list
      final migratedParticipants = meeting.participants.map((p) {
        if (!p.hasConfirmed) {
          print('[PARTICIPANT][MIGRATE] userId=${p.userId} name=${p.userName} pending->accepted');
          return MeetingParticipant(
            userId: p.userId,
            userName: p.userName,
            userEmail: p.userEmail,
            role: p.role,
            isRequired: p.isRequired,
            hasConfirmed: true,
            confirmedAt: DateTime.now(),
          );
        }
        return p;
      }).toList();

      // Ensure participantIds contains all userIds
      final participantIds = migratedParticipants.map((p) => p.userId).toList();

      // Update Firestore
      await _firestore.collection('meetings').doc(meeting.id).update({
        'participants': migratedParticipants.map((p) => p.toMap()).toList(),
        'participantIds': participantIds,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('[PARTICIPANT][MIGRATE] meetingId=${meeting.id} migration completed successfully');

      // Return updated meeting
      return meeting.copyWith(participants: migratedParticipants);
    } catch (e) {
      print('[PARTICIPANT][MIGRATE] meetingId=${meeting.id} ERROR: $e');
      // Return original meeting if migration fails
      return meeting;
    }
  }

  // ==================== Helper Methods for Approval Workflow ====================

  /// Send approval request notifications to all admins
  Future<void> _sendApprovalRequestToAdmins(
    MeetingModel meeting,
    NotificationProvider? notificationProvider,
  ) async {
    if (notificationProvider == null) return;

    try {
      // Get all admin users
      QuerySnapshot adminSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();

      print('🔄 Sending approval requests to ${adminSnapshot.docs.length} admins');

      for (var doc in adminSnapshot.docs) {
        await notificationProvider.createNotification(
          NotificationTemplate.meetingApprovalRequest(
            userId: doc.id,
            meetingTitle: meeting.title,
            meetingId: meeting.id,
            creatorName: meeting.creatorName,
          ),
        );
      }

      print('✅ Sent approval requests to admins for: ${meeting.title}');
    } catch (e) {
      print('❌ Error sending approval requests: $e');
    }
  }

  /// Send invitation notifications to all participants
  Future<void> _sendParticipantInvitations(
    MeetingModel meeting,
    NotificationProvider notificationProvider,
  ) async {
    try {
      // Get participant IDs (use latest from meeting)
      List<String> participantIds = meeting.participants.map((p) => p.userId).toList();

      print('🔄 Sending invitations to ${participantIds.length} participants');

      for (String participantId in participantIds) {
        await notificationProvider.createNotification(
          NotificationTemplate.meetingInvitation(
            userId: participantId,
            meetingTitle: meeting.title,
            meetingId: meeting.id,
            meetingTime: meeting.startTime,
            creatorName: meeting.creatorName,
          ),
        );
      }

      print('✅ Sent invitations to ${participantIds.length} participants for: ${meeting.title}');
    } catch (e) {
      print('❌ Error sending participant invitations: $e');
    }
  }
  
  // ==================== Task Management ====================

  List<MeetingTask> _allTasks = [];
  List<MeetingTask> get allTasks => _allTasks;

  /// Load all tasks for a specific user (assigned to or created by)
  Future<void> loadAllUserTasks(String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print('🔄 Loading all tasks for user: $userId');

      // Query 1: Tasks assigned to user
      QuerySnapshot assignedTasksSnapshot = await _firestore
          .collection('tasks')
          .where('assigneeId', isEqualTo: userId)
          .get();

      // Query 2: Tasks created by user
      QuerySnapshot createdTasksSnapshot = await _firestore
          .collection('tasks')
          .where('createdBy', isEqualTo: userId)
          .get();

      // Merge and deduplicate
      Map<String, MeetingTask> taskMap = {};

      for (var doc in assignedTasksSnapshot.docs) {
        taskMap[doc.id] = MeetingTask.fromMap(
            doc.data() as Map<String, dynamic>, doc.id);
      }

      for (var doc in createdTasksSnapshot.docs) {
        if (!taskMap.containsKey(doc.id)) {
          taskMap[doc.id] = MeetingTask.fromMap(
              doc.data() as Map<String, dynamic>, doc.id);
        }
      }

      _allTasks = taskMap.values.toList();
      
      // Sort: Completed last, then by deadline
      _allTasks.sort((a, b) {
        if (a.status == MeetingTaskStatus.completed && b.status != MeetingTaskStatus.completed) return 1;
        if (a.status != MeetingTaskStatus.completed && b.status == MeetingTaskStatus.completed) return -1;
        return a.deadline.compareTo(b.deadline);
      });

      print('✅ Loaded ${_allTasks.length} total tasks for user $userId');
    } catch (e) {
      _error = 'Lỗi tải danh sách công việc: $e';
      print('❌ Error loading all tasks: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

}


