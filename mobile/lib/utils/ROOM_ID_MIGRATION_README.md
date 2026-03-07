# Room ID Migration Guide

## Vấn đề

Hiện tại có mismatch về format `roomId` giữa các collections:

- **meetings.roomId**: Đang lưu dạng code (vd: `room_training_01`)
- **room_bookings.roomId**: Đang lưu dạng documentId (vd: `JAT7xHfDmoDGHmySQ8xA`)

Điều này gây ra conflict khi validate/query theo `roomId` - không match giữa 2 collections, nên vẫn cho phép double-booking.

## Giải pháp

Chuẩn hóa tất cả `roomId` về format **docId** (document ID từ Firestore):

- `meetings.roomId` → dùng `rooms/{docId}`
- `room_bookings.roomId` → dùng `rooms/{docId}`
- Code cũ như `room_training_01` sẽ được map sang docId tương ứng

## Cách chạy Migration

### Bước 1: Dry-run (kiểm tra trước)

```dart
import 'package:your_app/utils/room_id_migration.dart';

final migration = RoomIdMigration();
final result = await migration.dryRun();
print(result);
```

Dry-run sẽ:
- Liệt kê số lượng meetings/bookings cần migrate
- Báo lỗi nếu có roomId không tìm thấy trong rooms collection
- **KHÔNG** thay đổi dữ liệu

### Bước 2: Chạy migration thực tế

```dart
import 'package:your_app/utils/room_id_migration.dart';

final migration = RoomIdMigration();
final result = await migration.migrateAll();
print(result);
```

Migration sẽ:
- Load tất cả rooms và tạo mapping (code → docId, name → docId)
- Update `meetings.roomId` từ code sang docId
- Update `room_bookings.roomId` từ code sang docId
- Commit theo batch (500 operations/batch)

### Bước 3: Verify

Sau khi migration xong, kiểm tra:

1. **Check meetings**:
```dart
final meetings = await FirebaseFirestore.instance
    .collection('meetings')
    .where('roomId', isNull: false)
    .get();

for (var doc in meetings.docs) {
  final roomId = doc.data()['roomId'];
  print('Meeting ${doc.id}: roomId=$roomId');
  // roomId should be docId format (length > 10, alphanumeric)
}
```

2. **Check bookings**:
```dart
final bookings = await FirebaseFirestore.instance
    .collection('room_bookings')
    .where('roomId', isNull: false)
    .get();

for (var doc in bookings.docs) {
  final roomId = doc.data()['roomId'];
  print('Booking ${doc.id}: roomId=$roomId');
  // roomId should be docId format (length > 10, alphanumeric)
}
```

3. **Test double-booking prevention**:
   - Tạo meeting A với room X, time T → OK
   - Tạo meeting B cùng room X, overlap time T → Should be blocked ✅

## Mapping Strategy

Migration script sẽ map roomId theo thứ tự ưu tiên:

1. **Direct match**: `roomId == docId` (đã đúng format) → giữ nguyên
2. **Code match**: `roomId == room.id` (legacy code như `room_training_01`) → map sang `docId`
3. **Name match**: `roomId == room.name` (fallback) → map sang `docId`

## Logging

Sau khi migration, code đã được update để log roomId format:

- `[MEETING_CREATE][ROOM_SELECTED]`: Log khi user chọn room trong meeting creation
- `[BOOKING][CREATE][ROOM_SELECTED]`: Log khi tạo booking
- `[BOOKING][QUICK][ROOM_SELECTED]`: Log khi tạo quick booking
- `[BOOKING][VALIDATE]`: Log khi validate conflicts

Tất cả logs sẽ hiển thị:
- `roomId`: Giá trị roomId
- `isDocId`: true nếu là docId format (length > 10)

## Lưu ý

⚠️ **Backup dữ liệu trước khi chạy migration!**

Migration script sẽ:
- Update trực tiếp trên Firestore
- Commit theo batch (500 operations)
- Không thể rollback tự động

Nếu có lỗi, cần restore từ backup và fix mapping manually.

## Troubleshooting

### Lỗi: "roomId not found in rooms"

Có thể do:
1. Room đã bị xóa nhưng meetings/bookings vẫn reference
2. RoomId format không match với bất kỳ room nào

**Giải pháp**:
- Check rooms collection xem room có tồn tại không
- Update manually hoặc set `roomId = null` cho các records không tìm thấy room

### Lỗi: "Batch commit failed"

Có thể do:
1. Quá nhiều operations trong 1 batch (> 500)
2. Permission denied

**Giải pháp**:
- Script tự động split batch, nhưng nếu vẫn lỗi thì check permissions
- Chạy lại migration (idempotent - có thể chạy nhiều lần)

## Acceptance Criteria

✅ **Migration thành công khi**:

1. Tất cả `meetings.roomId` và `room_bookings.roomId` đều là docId format
2. Double-booking được prevent:
   - Tạo meeting A (room X, time T) → OK
   - Tạo meeting B cùng room X, overlap time T → Bị chặn (UI disable + backend error)
3. Works cho cả meeting flow và quickBooking flow
4. Logs hiển thị đúng roomId format
