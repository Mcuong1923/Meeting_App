# Hệ thống Quản lý Cuộc họp - MEETING_APP

## Tổng quan

Hệ thống quản lý cuộc họp được xây dựng với Flutter và Firebase, hỗ trợ đầy đủ các chức năng quản lý cuộc họp từ tạo lập, phê duyệt, đến tham gia.

## Cấu trúc hệ thống

### 1. Hệ thống Vai trò (Role System)

#### Các vai trò chính:
- **Super Admin**: Quản trị viên cấp cao - Toàn quyền hệ thống
- **Admin**: Quản trị viên - Quản lý phòng ban
- **Manager**: Quản lý - Quản lý team/dự án
- **Employee**: Nhân viên - Tạo cuộc họp cá nhân
- **Guest**: Khách - Chỉ tham gia cuộc họp được mời

#### Quyền tạo cuộc họp:
| Vai trò | Cuộc họp cá nhân | Cuộc họp team | Cuộc họp department | Cuộc họp công ty |
|---------|------------------|---------------|-------------------|------------------|
| Super Admin | ✅ | ✅ | ✅ | ✅ |
| Admin | ✅ | ✅ | ✅ | ✅ |
| Manager | ✅ | ✅ | ⚠️ (cần phê duyệt) | ❌ |
| Employee | ⚠️ (cần phê duyệt) | ⚠️ (cần phê duyệt) | ❌ | ❌ |
| Guest | ❌ | ❌ | ❌ | ❌ |

### 2. Loại cuộc họp

- **Personal**: Cuộc họp cá nhân
- **Team**: Cuộc họp team/dự án
- **Department**: Cuộc họp phòng ban
- **Company**: Cuộc họp toàn công ty

### 3. Trạng thái cuộc họp

- **Pending**: Chờ phê duyệt
- **Approved**: Đã phê duyệt
- **Rejected**: Bị từ chối
- **Cancelled**: Đã hủy
- **Completed**: Đã hoàn thành

### 4. Loại địa điểm

- **Physical**: Cuộc họp trực tiếp
- **Virtual**: Cuộc họp trực tuyến
- **Hybrid**: Cuộc họp kết hợp

## Các chức năng chính

### 1. Quản lý người dùng
- Đăng ký/Đăng nhập với email hoặc Google
- Phân quyền theo vai trò
- Quản lý thông tin cá nhân

### 2. Tạo cuộc họp
- Form tạo cuộc họp đầy đủ thông tin
- Chọn loại cuộc họp theo quyền
- Thiết lập thời gian, địa điểm
- Thêm người tham gia
- Cài đặt cuộc họp (mật khẩu, ghi âm, etc.)

### 3. Phê duyệt cuộc họp
- Workflow phê duyệt tự động
- Thông báo cho người phê duyệt
- Gửi kết quả phê duyệt cho người tạo

### 4. Quản lý cuộc họp
- Xem danh sách cuộc họp (tất cả, chờ phê duyệt, của tôi)
- Chỉnh sửa, xóa cuộc họp
- Phê duyệt/từ chối cuộc họp

## Cấu trúc Database

### Collections chính:

#### 1. users
```json
{
  "id": "user_id",
  "email": "user@example.com",
  "displayName": "Tên người dùng",
  "photoURL": "https://...",
  "role": "employee",
  "departmentId": "dept_id",
  "departmentName": "Tên phòng ban",
  "managerId": "manager_id",
  "managerName": "Tên quản lý",
  "teamIds": ["team1", "team2"],
  "teamNames": ["Team A", "Team B"],
  "createdAt": "timestamp",
  "lastLoginAt": "timestamp",
  "isActive": true
}
```

#### 2. meetings
```json
{
  "id": "meeting_id",
  "title": "Tiêu đề cuộc họp",
  "description": "Mô tả cuộc họp",
  "type": "personal",
  "status": "pending",
  "locationType": "physical",
  "priority": "medium",
  "startTime": "timestamp",
  "endTime": "timestamp",
  "durationMinutes": 60,
  "physicalLocation": "Phòng họp A",
  "virtualMeetingLink": "https://zoom.us/...",
  "virtualMeetingPassword": "123456",
  "creatorId": "user_id",
  "creatorName": "Tên người tạo",
  "participants": [
    {
      "userId": "user_id",
      "userName": "Tên người tham gia",
      "userEmail": "email@example.com",
      "role": "participant",
      "isRequired": true,
      "hasConfirmed": false
    }
  ],
  "agenda": "Chương trình cuộc họp",
  "attachments": ["file1.pdf", "file2.docx"],
  "meetingNotes": "Ghi chú cuộc họp",
  "actionItems": ["Việc 1", "Việc 2"],
  "approverId": "approver_id",
  "approverName": "Tên người phê duyệt",
  "approvedAt": "timestamp",
  "approvalNotes": "Ghi chú phê duyệt",
  "createdAt": "timestamp",
  "updatedAt": "timestamp",
  "departmentId": "dept_id",
  "departmentName": "Tên phòng ban",
  "tags": ["tag1", "tag2"],
  "isRecurring": false,
  "recurringPattern": "weekly",
  "recurringEndDate": "timestamp",
  "allowJoinBeforeHost": true,
  "muteOnEntry": false,
  "recordMeeting": false,
  "requirePassword": false
}
```

#### 3. notifications
```json
{
  "id": "notification_id",
  "userId": "user_id",
  "title": "Tiêu đề thông báo",
  "message": "Nội dung thông báo",
  "type": "meeting_approval",
  "meetingId": "meeting_id",
  "createdAt": "timestamp",
  "isRead": false
}
```

## Workflow hoạt động

### 1. Quy trình tạo cuộc họp
```
1. User đăng nhập → Kiểm tra vai trò
2. Chọn loại cuộc họp → Kiểm tra quyền
3. Điền thông tin → Validation
4. Chọn người tham gia → Availability check
5. Chọn phòng họp → Room booking
6. Gửi yêu cầu phê duyệt (nếu cần)
7. Nhận phê duyệt → Tạo cuộc họp
8. Gửi thông báo → Calendar sync
```

### 2. Quy trình phê duyệt
```
1. Nhận yêu cầu → Review thông tin
2. Kiểm tra conflict → Time/room/participant
3. Đánh giá priority → Business impact
4. Phê duyệt/từ chối → Gửi feedback
5. Auto-schedule → Nếu được phê duyệt
6. Notification → Tất cả stakeholders
```

## Cài đặt và chạy

### 1. Yêu cầu hệ thống
- Flutter SDK 3.0+
- Dart 2.19+
- Firebase project
- Android Studio / VS Code

### 2. Cài đặt dependencies
```bash
cd mobile
flutter pub get
```

### 3. Cấu hình Firebase
1. Tạo project Firebase mới
2. Thêm ứng dụng Android/iOS
3. Tải file `google-services.json` (Android) hoặc `GoogleService-Info.plist` (iOS)
4. Bật Authentication với Email/Password và Google Sign-in
5. Tạo Firestore Database
6. Cấu hình Security Rules

### 4. Chạy ứng dụng
```bash
flutter run
```

## Security Rules cho Firestore

### Users Collection
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      // Admins can read all users
      allow read: if request.auth != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['super_admin', 'admin'];
    }
  }
}
```

### Meetings Collection
```javascript
match /meetings/{meetingId} {
  // Creator can read/write their meetings
  allow read, write: if request.auth != null && 
    resource.data.creatorId == request.auth.uid;
  
  // Participants can read meetings they're invited to
  allow read: if request.auth != null && 
    request.auth.uid in resource.data.participants[*].userId;
  
  // Admins can read/write all meetings in their department
  allow read, write: if request.auth != null && 
    get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ['super_admin', 'admin'] &&
    resource.data.departmentId == get(/databases/$(database)/documents/users/$(request.auth.uid)).data.departmentId;
}
```

## Tính năng nâng cao (Roadmap)

### Phase 1 (Core Features) ✅
- [x] Hệ thống vai trò và phân quyền
- [x] Tạo và quản lý cuộc họp
- [x] Workflow phê duyệt
- [x] Thông báo cơ bản

### Phase 2 (Advanced Management)
- [ ] Quản lý phòng họp
- [ ] Calendar integration
- [ ] Email notifications
- [ ] Reporting & analytics

### Phase 3 (Automation & AI)
- [ ] Smart scheduling
- [ ] Auto-summarization
- [ ] Voice-to-text
- [ ] Meeting insights

### Phase 4 (Enterprise Features)
- [ ] SSO integration
- [ ] Advanced security
- [ ] Custom workflows
- [ ] Mobile app optimization

## Đóng góp

1. Fork project
2. Tạo feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Tạo Pull Request

## License

Distributed under the MIT License. See `LICENSE` for more information.

## Liên hệ

- Email: support@meetingapp.com
- Website: https://meetingapp.com
- Documentation: https://docs.meetingapp.com 