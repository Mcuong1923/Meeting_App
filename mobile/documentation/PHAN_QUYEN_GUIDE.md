# Hướng Dẫn Phân Quyền - Meeting App

## 🎯 Tổng Quan

Hệ thống phân quyền trong Meeting App được thiết kế với 5 vai trò chính, mỗi vai trò có quyền hạn khác nhau để đảm bảo bảo mật và hiệu quả trong quản lý cuộc họp.

## 👥 Các Vai Trò Trong Hệ Thống

### 1. **Super Admin** 🔴
- **Quyền cao nhất** trong hệ thống
- **Màu sắc**: Đỏ
- **Icon**: `admin_panel_settings`

**Quyền hạn:**
- ✅ Tạo tất cả loại cuộc họp
- ✅ Phê duyệt tất cả cuộc họp
- ✅ Quản lý tất cả người dùng
- ✅ Thay đổi vai trò người dùng
- ✅ Xem tất cả báo cáo
- ✅ Cấu hình hệ thống
- ✅ Xóa cuộc họp
- ✅ Quản lý phòng họp

### 2. **Admin** 🟠
- **Quản lý cấp trung**
- **Màu sắc**: Cam
- **Icon**: `manage_accounts`

**Quyền hạn:**
- ✅ Tạo cuộc họp (trừ Super Admin)
- ✅ Phê duyệt cuộc họp (trừ Super Admin)
- ✅ Quản lý người dùng (Employee, Guest)
- ✅ Xem báo cáo
- ✅ Quản lý phòng họp

### 3. **Manager** 🔵
- **Quản lý nhóm**
- **Màu sắc**: Xanh dương
- **Icon**: `people`

**Quyền hạn:**
- ✅ Tạo cuộc họp thường
- ✅ Phê duyệt cuộc họp trong nhóm
- ✅ Quản lý thành viên nhóm
- ✅ Xem báo cáo nhóm

### 4. **Employee** 🟢
- **Nhân viên thường**
- **Màu sắc**: Xanh lá
- **Icon**: `person`

**Quyền hạn:**
- ✅ Tạo cuộc họp cá nhân
- ✅ Tham gia cuộc họp
- ✅ Xem cuộc họp được mời
- ✅ Cập nhật thông tin cá nhân

### 5. **Guest** ⚪
- **Khách**
- **Màu sắc**: Xám
- **Icon**: `person_outline`

**Quyền hạn:**
- ✅ Tham gia cuộc họp được mời
- ✅ Xem thông tin cuộc họp
- ❌ Không thể tạo cuộc họp

## 🚀 Cách Thiết Lập Phân Quyền

### Bước 1: Thiết Lập Super Admin Đầu Tiên

Khi chạy ứng dụng lần đầu tiên:

1. **Đăng nhập** vào ứng dụng
2. **Hệ thống sẽ hiển thị dialog** hỏi có muốn thiết lập Super Admin
3. **Chọn "Thiết lập ngay"**
4. **Xác nhận** để trở thành Super Admin đầu tiên

**Lưu ý**: Chỉ có thể thiết lập Super Admin **một lần duy nhất**!

### Bước 2: Quản Lý Vai Trò Người Dùng

**Chỉ Super Admin mới có quyền thay đổi vai trò:**

1. **Vào Settings** (Cài đặt)
2. **Chọn "Quản lý vai trò"** (chỉ hiển thị cho Super Admin)
3. **Xem danh sách tất cả người dùng**
4. **Nhấn vào menu 3 chấm** bên cạnh tên người dùng
5. **Chọn vai trò mới** từ danh sách
6. **Xác nhận thay đổi**

### Bước 3: Kiểm Tra Quyền

**Cách kiểm tra vai trò hiện tại:**

1. **Vào Settings** → **Thông tin cá nhân**
2. **Xem chip màu** hiển thị vai trò
3. **Hoặc vào menu chính** → **Thông tin user**

## 🎨 Giao Diện Phân Quyền

### Màu Sắc Vai Trò
- **Super Admin**: 🔴 Đỏ
- **Admin**: 🟠 Cam  
- **Manager**: 🔵 Xanh dương
- **Employee**: 🟢 Xanh lá
- **Guest**: ⚪ Xám

### Hiển Thị Trong App
- **Chip màu** bên cạnh tên người dùng
- **Icon tương ứng** trong menu
- **Màu nền** khác nhau cho mỗi vai trò

## 🔒 Bảo Mật

### Kiểm Tra Quyền Trong Code
```dart
// Kiểm tra quyền tạo cuộc họp
if (authProvider.userModel?.canCreateMeeting == true) {
  // Hiển thị nút tạo cuộc họp
}

// Kiểm tra quyền phê duyệt
if (authProvider.userModel?.canApproveMeeting == true) {
  // Hiển thị nút phê duyệt
}
```

### Firestore Security Rules
```javascript
// Chỉ Super Admin mới có quyền thay đổi vai trò
match /users/{userId} {
  allow update: if request.auth != null && 
    get(/databases/$(database.name)/documents/users/$(request.auth.uid)).data.role == 'superAdmin';
}
```

## 📱 Sử Dụng Trong App

### 1. **Tạo Cuộc Họp**
- **Employee**: Chỉ tạo cuộc họp cá nhân
- **Manager**: Tạo cuộc họp nhóm
- **Admin/Super Admin**: Tạo tất cả loại cuộc họp

### 2. **Phê Duyệt Cuộc Họp**
- **Manager**: Phê duyệt cuộc họp nhóm
- **Admin**: Phê duyệt tất cả (trừ Super Admin)
- **Super Admin**: Phê duyệt tất cả

### 3. **Quản Lý Người Dùng**
- **Admin**: Quản lý Employee, Guest
- **Super Admin**: Quản lý tất cả

### 4. **Xem Báo Cáo**
- **Manager**: Báo cáo nhóm
- **Admin**: Tất cả báo cáo
- **Super Admin**: Tất cả báo cáo + cấu hình

## ⚠️ Lưu Ý Quan Trọng

1. **Super Admin không thể bị xóa** hoặc hạ cấp
2. **Chỉ có 1 Super Admin** trong hệ thống
3. **Vai trò được lưu trong Firestore** và đồng bộ real-time
4. **Quyền được kiểm tra** ở cả frontend và backend
5. **Không thể tạo Super Admin mới** nếu đã có

## 🛠️ Troubleshooting

### Lỗi "Không có quyền truy cập"
- Kiểm tra vai trò hiện tại
- Đảm bảo đã đăng nhập
- Liên hệ Super Admin để được cấp quyền

### Không thấy menu "Quản lý vai trò"
- Chỉ Super Admin mới thấy menu này
- Kiểm tra vai trò trong Settings

### Không thể thay đổi vai trò
- Chỉ Super Admin mới có quyền
- Kiểm tra kết nối internet
- Thử lại sau vài giây

## 📞 Hỗ Trợ

Nếu gặp vấn đề với phân quyền:
1. Kiểm tra vai trò hiện tại
2. Đọc lại hướng dẫn này
3. Liên hệ Super Admin
4. Gửi báo cáo lỗi chi tiết 