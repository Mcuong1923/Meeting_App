# 📚 Tài Liệu Hướng Dẫn - Meeting App

Thư mục này chứa tất cả tài liệu hướng dẫn và báo cáo cho dự án Meeting App.

## 📋 Danh Sách Tài Liệu

### 🔐 **AUTH_FEATURES.md**
- **Mô tả**: Hướng dẫn chi tiết về hệ thống xác thực
- **Nội dung**: 
  - Đăng nhập/đăng ký
  - Xác thực Google
  - Quản lý phiên đăng nhập
  - Bảo mật tài khoản

### 🛠️ **BUILD_FIX_README.md**
- **Mô tả**: Hướng dẫn sửa lỗi build và cấu hình
- **Nội dung**:
  - Cấu hình Gradle
  - Sửa lỗi build Android
  - Cài đặt dependencies
  - Troubleshooting

### 🔥 **FIREBASE_SETUP.md**
- **Mô tả**: Hướng dẫn thiết lập Firebase
- **Nội dung**:
  - Tạo project Firebase
  - Cấu hình Authentication
  - Thiết lập Firestore
  - Deploy Cloud Functions

### 🏢 **MEETING_SYSTEM_README.md**
- **Mô tả**: Tài liệu tổng quan hệ thống
- **Nội dung**:
  - Kiến trúc hệ thống
  - Tính năng chính
  - Workflow cuộc họp
  - Database schema

### 👥 **PHAN_QUYEN_GUIDE.md**
- **Mô tả**: Hướng dẫn phân quyền người dùng
- **Nội dung**:
  - 5 vai trò trong hệ thống
  - Cách thiết lập Super Admin
  - Quản lý vai trò người dùng
  - Bảo mật và troubleshooting

## 🎯 Cách Sử Dụng

### Cho Developer:
1. **Bắt đầu**: Đọc `MEETING_SYSTEM_README.md` để hiểu tổng quan
2. **Setup**: Làm theo `FIREBASE_SETUP.md` để cấu hình backend
3. **Build**: Tham khảo `BUILD_FIX_README.md` nếu gặp lỗi
4. **Auth**: Xem `AUTH_FEATURES.md` để hiểu hệ thống xác thực
5. **Permission**: Đọc `PHAN_QUYEN_GUIDE.md` để setup phân quyền

### Cho User:
1. **Cài đặt**: Làm theo `FIREBASE_SETUP.md`
2. **Phân quyền**: Đọc `PHAN_QUYEN_GUIDE.md`
3. **Sử dụng**: Tham khảo `MEETING_SYSTEM_README.md`

## 📁 Cấu Trúc Thư Mục

```
mobile/
├── documentation/          # 📚 Tài liệu hướng dẫn
│   ├── README.md          # 📋 File này
│   ├── AUTH_FEATURES.md   # 🔐 Hệ thống xác thực
│   ├── BUILD_FIX_README.md # 🛠️ Sửa lỗi build
│   ├── FIREBASE_SETUP.md  # 🔥 Cấu hình Firebase
│   ├── MEETING_SYSTEM_README.md # 🏢 Tổng quan hệ thống
│   └── PHAN_QUYEN_GUIDE.md # 👥 Hướng dẫn phân quyền
├── lib/                   # 💻 Source code Flutter
├── android/              # 🤖 Android configuration
├── ios/                  # 🍎 iOS configuration
└── docs                  # 📊 Báo cáo tiến độ (giữ nguyên)
```

## 🔄 Cập Nhật Tài Liệu

Khi có thay đổi trong hệ thống:
1. **Cập nhật** file tương ứng
2. **Kiểm tra** tính chính xác
3. **Commit** với message rõ ràng
4. **Thông báo** team về thay đổi

## 📞 Hỗ Trợ

Nếu có vấn đề với tài liệu:
1. Kiểm tra phiên bản mới nhất
2. Đọc kỹ hướng dẫn
3. Tìm kiếm trong các file khác
4. Liên hệ team để được hỗ trợ

---

**Lưu ý**: File `docs` ở thư mục gốc là báo cáo tiến độ, không di chuyển vào đây. 