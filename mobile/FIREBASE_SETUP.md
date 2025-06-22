# Hướng dẫn cấu hình Firebase Authentication

## 1. Kiểm tra Firebase Console

### Bước 1: Truy cập Firebase Console
1. Mở trình duyệt và truy cập: https://console.firebase.google.com/
2. Đăng nhập bằng tài khoản Google của bạn
3. Chọn project `mettingapp-aef60`

### Bước 2: Bật Authentication
1. Trong menu bên trái, chọn **Authentication**
2. Chọn tab **Sign-in method**
3. Tìm **Email/Password** và click vào nó
4. Bật toggle **Enable**
5. Click **Save**

### Bước 3: Kiểm tra cấu hình
1. Trong tab **Users**, bạn sẽ thấy danh sách người dùng đã đăng ký
2. Trong tab **Settings**, kiểm tra thông tin project

## 2. Kiểm tra Firestore Database

### Bước 1: Truy cập Firestore
1. Trong menu bên trái, chọn **Firestore Database**
2. Nếu chưa có database, click **Create database**
3. Chọn **Start in test mode** (cho development)
4. Chọn location gần nhất (ví dụ: asia-southeast1)

### Bước 2: Tạo collection users
1. Click **Start collection**
2. Collection ID: `users`
3. Document ID: `auto-id`
4. Thêm các field:
   - `email` (string)
   - `displayName` (string)
   - `createdAt` (timestamp)
   - `lastLoginAt` (timestamp)

## 3. Kiểm tra Security Rules

### Firestore Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Cho phép người dùng đã đăng nhập đọc/ghi dữ liệu của mình
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Cho phép đọc/ghi meetings (sẽ cập nhật sau)
    match /meetings/{meetingId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## 4. Test chức năng

### Test đăng ký
1. Chạy ứng dụng: `flutter run`
2. Chọn **Sign Up**
3. Nhập email và mật khẩu
4. Kiểm tra trong Firebase Console > Authentication > Users

### Test đăng nhập
1. Chọn **Sign In**
2. Nhập email và mật khẩu đã đăng ký
3. Kiểm tra chuyển đến màn hình Home

### Test đăng xuất
1. Trong màn hình Home, click icon logout
2. Kiểm tra quay về màn hình Login

## 5. Troubleshooting

### Lỗi "Email đã được sử dụng"
- Kiểm tra trong Firebase Console > Authentication > Users
- Xóa user cũ nếu cần

### Lỗi "Mật khẩu quá yếu"
- Mật khẩu phải có ít nhất 6 ký tự

### Lỗi "Email không hợp lệ"
- Kiểm tra định dạng email

### Lỗi kết nối
- Kiểm tra internet connection
- Kiểm tra cấu hình Firebase trong `firebase_options.dart` 