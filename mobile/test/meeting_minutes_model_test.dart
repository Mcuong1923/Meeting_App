import 'package:flutter_test/flutter_test.dart';
import 'package:metting_app/models/meeting_minutes_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('MeetingMinutesModel Tests', () {
    test('Status Parsing should be strict', () {
      // Test draft
      expect(MeetingMinutesModel.fromMap({'status': 'draft'}, '1').status, MinutesStatus.draft);
      
      // Test pending mapping
      expect(MeetingMinutesModel.fromMap({'status': 'pending'}, '2').status, MinutesStatus.pending_approval);
      expect(MeetingMinutesModel.fromMap({'status': 'pending_approval'}, '3').status, MinutesStatus.pending_approval);
      
      // Test approved
      expect(MeetingMinutesModel.fromMap({'status': 'approved'}, '4').status, MinutesStatus.approved);
      
      // Test rejected
      expect(MeetingMinutesModel.fromMap({'status': 'rejected'}, '5').status, MinutesStatus.rejected);
      
      // Test unknown defaults to draft
      expect(MeetingMinutesModel.fromMap({'status': 'unknown_status'}, '6').status, MinutesStatus.draft);
      expect(MeetingMinutesModel.fromMap({}, '7').status, MinutesStatus.draft);
    });

    test('Helper Getters should match Status', () {
      final draft = MeetingMinutesModel(
        id: '1', meetingId: 'm1', title: 'T', content: 'C', versionNumber: 1,
        status: MinutesStatus.draft,
        createdBy: 'u1', createdByName: 'n1', createdAt: DateTime.now(),
        updatedBy: 'u1', updatedByName: 'n1', updatedAt: DateTime.now(),
      );
      
      expect(draft.isDraft, true);
      expect(draft.isPending, false);
      expect(draft.canEdit, true);
      expect(draft.canSubmit, true);
      expect(draft.canApprove, false);

      final pending = draft.copyWith(status: MinutesStatus.pending_approval);
      expect(pending.isPending, true);
      expect(pending.canEdit, false);
      expect(pending.canSubmit, false); // Already submitted
      expect(pending.canApprove, true); // Logic allows approval state calc (permission check is external)

      final approved = draft.copyWith(status: MinutesStatus.approved);
      expect(approved.isApproved, true);
      expect(approved.canEdit, false);
      expect(approved.canApprove, false);
    });
  });
}
