# Bug Fix Summary - Auto-Approve & Conflict Detection

## Files Modified

### 1. `mobile/lib/providers/meeting_provider.dart`

#### Bug 1 Fix: Admin Auto-Approve (Lines ~612-650)

**Problem**: Admin tạo meeting nhưng vẫn bị pending thay vì auto-approve.

**Solution**:
- Check `currentUser.needsApproval(meeting.type)` để xác định có cần approval không
- Nếu `canAutoApprove = true` (admin/director/manager):
  - Set `status = MeetingStatus.approved`
  - Set `approvalStatus = MeetingApprovalStatus.auto_approved`
  - Set `approvedAt = now`
  - Set `approvedBy`, `approverId`, `approverName = currentUser`
- Nếu `canAutoApprove = false` (employee):
  - Giữ logic cũ: `status = pending`, `approvalStatus = pending`, set `expiresAt`

**Key Changes**:
```dart
// Determine if user can auto-approve (admin/director/manager)
final needsApproval = currentUser.needsApproval(meeting.type);
final canAutoApprove = !needsApproval;

if (canAutoApprove) {
  initialStatus = MeetingStatus.approved;
  initialApprovalStatus = MeetingApprovalStatus.auto_approved;
  approvedAt = DateTime.now();
  approvedBy = currentUser.id;
  approverId = currentUser.id;
  approverName = currentUser.displayName;
}
```

#### Bug 2 Fix: Conflict Detection (Lines ~170-453)

**Problem**: Conflict detection lọt do:
- Dùng allow-list cứng (`['pending', 'approved']`) → bỏ sót status khác
- Không handle legacy data (roomId null, legacy format)
- Không handle status inconsistencies (status=approved nhưng approvalStatus=pending)
- Silent fail khi query requires index

**Solution**:
1. **Exclude-list approach**: Thay vì allow-list, dùng exclude-list:
   - Meetings: exclude `['cancelled', 'rejected', 'expired', 'completed']`
   - Bookings: exclude `['cancelled', 'rejected', 'releasedBySystem', 'completed']`
   - Tất cả status khác đều coi là active

2. **Handle legacy data**:
   - Skip meetings/bookings không có `roomId`
   - Log warning cho status inconsistencies
   - Query tất cả records rồi filter bằng code (không filter trong query)

3. **Error handling**:
   - Nếu query requires index → throw error với message rõ ràng (không return empty)
   - Log đầy đủ: candidates count, skipped count, conflicts count

**Key Changes**:
```dart
// Exclude-list approach
static const List<String> _inactiveMeetingStatuses = [
  'cancelled', 'rejected', 'expired', 'completed',
];

// Query all, then filter
QuerySnapshot snapshot = await _firestore
    .collection('meetings')
    .where('roomId', isEqualTo: roomId)
    .get(); // No status filter in query

// Filter in code
if (_inactiveMeetingStatuses.contains(statusStr)) {
  skippedInactive++;
  continue;
}
```

## Test Cases

### Test 1: Admin Create Meeting → Should Auto-Approve

**Steps**:
1. Login với admin account
2. Tạo meeting với future time
3. Check meeting status

**Expected**:
- `status = approved`
- `approvalStatus = auto_approved`
- `approvedBy = admin userId`
- `approvedAt = now`
- Meeting không xuất hiện trong pending approvals list

**Log Output**:
```
[MEETING][CREATE] User role=UserRole.admin needsApproval=false canAutoApprove=true
[MEETING][CREATE] AUTO-APPROVE: status=MeetingStatus.approved approvalStatus=MeetingApprovalStatus.auto_approved approvedBy=...
[MEETING][CREATE] Final payload: status=approved approvalStatus=auto_approved approvedBy=...
```

### Test 2: Employee Create Meeting → Should Be Pending

**Steps**:
1. Login với employee account
2. Tạo meeting
3. Check meeting status

**Expected**:
- `status = pending`
- `approvalStatus = pending`
- `approvedBy = null`
- Meeting xuất hiện trong pending approvals list

**Log Output**:
```
[MEETING][CREATE] User role=UserRole.employee needsApproval=true canAutoApprove=false
[MEETING][CREATE] PENDING APPROVAL: status=MeetingStatus.pending approvalStatus=MeetingApprovalStatus.pending expiresAt=...
```

### Test 3: Double Booking Prevention

**Steps**:
1. Tạo meeting A: room X, 10:00-11:00 → Should succeed
2. Tạo meeting B: room X, 10:30-11:30 → Should be blocked (overlap)
3. Restart app
4. Try Test 2 again → Should still be blocked

**Expected**:
- Meeting A created successfully
- Meeting B blocked with error message
- After restart, Meeting B still blocked (not dependent on cache)

**Log Output**:
```
[BOOKING][VALIDATE] START
[BOOKING][VALIDATE] roomId=JAT7xHfDmoDGHmySQ8xA (length=20, isDocId=true)
[BOOKING][CONFLICT_CHECK] Query returned 1 total meetings for roomId=...
[BOOKING][CONFLICT_CHECK] RESULT: 1 active conflicts found
[BOOKING][CONFLICT_CHECK] Sample conflict: id=abc123 roomId=... start=... end=... status=approved
[BOOKING][VALIDATE] RESULT: meetingConflicts=1 bookingConflicts=0
```

### Test 4: Past Time Validation

**Steps**:
1. Try to create meeting with startTime = now - 10 minutes
2. Check frontend validation
3. Check backend validation

**Expected**:
- Frontend: Button disabled, SnackBar error
- Backend: Exception thrown with clear message

**Log Output**:
```
[MEETING_CREATE] VALIDATION FAILED: startDateTime=... is before minStartTime=...
[MEETING][CREATE] VALIDATION FAILED: startTime=... is before minStartTime=...
```

### Test 5: Boundary Case (Touching)

**Steps**:
1. Tạo meeting A: room X, 10:00-11:00 → OK
2. Tạo meeting B: room X, 11:00-12:00 → Should succeed (touching boundary, no overlap)

**Expected**:
- Both meetings created successfully
- No conflict detected (end == start is NOT a conflict)

## Firestore Index Requirements

Nếu query conflict detection requires index, bạn sẽ thấy error message với link tạo index:

```
The query requires an index. You can create it here: 
https://console.firebase.google.com/v1/r/project/.../firestore/indexes?create_composite=...
```

**Required Indexes**:
1. **meetings collection**:
   - Fields: `roomId` (ASC), `status` (ASC)
   - Query: `where('roomId', isEqualTo: roomId)`

2. **room_bookings collection**:
   - Fields: `roomId` (ASC), `status` (ASC)
   - Query: `where('roomId', isEqualTo: roomId)`

**Note**: Với exclude-list approach, query không filter status trong Firestore nên không cần composite index với status field. Chỉ cần index trên `roomId` là đủ.

## Migration Notes

Sau khi fix, cần chạy migration script để chuẩn hóa roomId:

```dart
import 'package:your_app/utils/room_id_migration.dart';

final migration = RoomIdMigration();
final result = await migration.migrateAll();
print(result);
```

Migration sẽ:
- Map legacy roomId (code format) → docId format
- Update cả `meetings` và `room_bookings` collections
- Log số lượng records migrated

## Verification Checklist

- [ ] Admin tạo meeting → auto-approve ✅
- [ ] Employee tạo meeting → pending ✅
- [ ] Double booking bị chặn ✅
- [ ] Past time bị chặn (frontend + backend) ✅
- [ ] Conflict detection works sau restart app ✅
- [ ] Logs hiển thị đầy đủ thông tin ✅
- [ ] Handle legacy data (roomId null, status inconsistencies) ✅
- [ ] Index errors fail hard với clear message ✅
