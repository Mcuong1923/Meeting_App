# Chức năng Đăng nhập và Đăng ký với Firebase Auth

## ✅ Đã triển khai

### 1. **AuthProvider** (`lib/providers/auth_provider.dart`)
- **Đăng ký tài khoản:** `signup(email, password, {displayName})`
  - Tạo tài khoản với Firebase Auth
  - Lưu thông tin người dùng vào Firestore
  - Xử lý lỗi chi tiết (email đã tồn tại, mật khẩu yếu, etc.)
  
- **Đăng nhập:** `login(email, password)`
  - Xác thực với Firebase Auth
  - Cập nhật thời gian đăng nhập cuối
  - Xử lý lỗi (sai mật khẩu, tài khoản không tồn tại, etc.)
  
- **Đăng xuất:** `logout()`
  - Thoát khỏi phiên đăng nhập
  - Xóa thông tin người dùng local
  
- **Đặt lại mật khẩu:** `resetPassword(email)`
  - Gửi email đặt lại mật khẩu
  
- **Cập nhật profile:** `updateProfile({displayName, photoURL})`
  - Cập nhật thông tin người dùng
  
- **Lấy thông tin người dùng:** `getUserData()`
  - Lấy dữ liệu từ Firestore

### 2. **Màn hình Đăng nhập** (`lib/screens/login_screen.dart`)
- Form validation (email, mật khẩu)
- Loading state khi đăng nhập
- Hiển thị thông báo lỗi/thành công
- Chuyển hướng đến màn hình Home sau khi đăng nhập thành công
- Link đến màn hình đăng ký

### 3. **Màn hình Đăng ký** (`lib/screens/signup_screen.dart`)
- Form validation (email, mật khẩu, xác nhận mật khẩu)
- Loading state khi đăng ký
- Hiển thị thông báo lỗi/thành công
- Chuyển hướng đến màn hình Home sau khi đăng ký thành công
- Link đến màn hình đăng nhập

### 4. **Màn hình Home** (`lib/screens/home_screen.dart`)
- Hiển thị thông tin người dùng (email, ID)
- Nút đăng xuất
- Menu chức năng chính (đang phát triển)
- Chuyển hướng về màn hình đăng nhập sau khi đăng xuất

## 🔧 Cấu hình Firebase

### Dependencies trong `pubspec.yaml`:
```yaml
firebase_core: ^2.0.0
firebase_auth: ^4.0.0
cloud_firestore: ^4.0.0
```

### Cấu hình đa nền tảng:
- ✅ Android
- ✅ iOS  
- ✅ Web (có lỗi tương thích)
- ✅ Windows
- ✅ macOS

## 🚀 Cách sử dụng

### 1. Chạy ứng dụng:
```bash
flutter run
```

### 2. Test đăng ký:
1. Chọn "Sign Up"
2. Nhập email hợp lệ
3. Nhập mật khẩu (ít nhất 6 ký tự)
4. Nhập lại mật khẩu
5. Click "ĐĂNG KÝ"

### 3. Test đăng nhập:
1. Chọn "Sign In"
2. Nhập email và mật khẩu đã đăng ký
3. Click "Đăng nhập"

### 4. Test đăng xuất:
1. Trong màn hình Home, click icon logout
2. Kiểm tra quay về màn hình Login

## 📊 Dữ liệu được lưu

### Firebase Authentication:
- Email
- Mật khẩu (được mã hóa)
- UID (User ID)

### Firestore Database:
Collection: `users`
```json
{
  "email": "user@example.com",
  "displayName": "Tên người dùng",
  "createdAt": "2024-01-01T00:00:00Z",
  "lastLoginAt": "2024-01-01T00:00:00Z"
}
```

## 🛡️ Bảo mật

### Validation:
- Email phải đúng định dạng
- Mật khẩu ít nhất 6 ký tự
- Xác nhận mật khẩu phải khớp

### Error Handling:
- Email đã được sử dụng
- Mật khẩu không đúng
- Tài khoản không tồn tại
- Email không hợp lệ
- Mật khẩu quá yếu

## 🔄 State Management

Sử dụng **Provider** pattern:
- `AuthProvider` quản lý trạng thái đăng nhập
- `Consumer<AuthProvider>` để lắng nghe thay đổi
- `notifyListeners()` để cập nhật UI

## 📱 UI/UX Features

- Loading indicators
- Form validation với error messages
- SnackBar notifications
- Responsive design
- Material Design 3
- Smooth navigation transitions

## 🎯 Next Steps

1. **Thêm chức năng đăng nhập bằng Google/Facebook**
2. **Thêm chức năng quên mật khẩu**
3. **Thêm chức năng cập nhật profile**
4. **Thêm chức năng xóa tài khoản**
5. **Thêm chức năng đổi mật khẩu**
6. **Thêm chức năng xác thực email**
7. **Thêm chức năng đăng nhập bằng số điện thoại** 