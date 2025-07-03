# Báo cáo tiến độ project - Tuần 3

**Thời gian:** Ngày 28/06/2025

**Sinh viên thực hiện:** Nguyễn Mạnh Cường
**Giảng viên hướng dẫn:** Lê Hoàng Anh

---

### 1. Các công việc đã hoàn thành

*   **Kết nối & thử nghiệm trên thiết bị thật:**
    *   Hướng dẫn và cấu hình **Developer Options**, bật **USB Debugging** cho thiết bị LG và iPhone.
    *   Khắc phục lỗi thiết bị LG chỉ hiển thị trạng thái **Charging** (sạc) bằng cách chọn thủ công _USB Configuration → File Transfer (MTP)_.
    *   Thử nghiệm ADB qua Wi-Fi và các công cụ mirroring (Vysor, Scrcpy) để thay thế máy ảo.
*   **Refactor Bottom Navigation Bar:**
    *   Thử nghiệm nhiều phương án (CurvedNavigationBar, CustomPainter) để đáp ứng thiết kế bo góc, icon nền tròn, hiệu ứng "lõm" khi chọn tab.
    *   Xây dựng component `CustomBottomNavBar` mới, animation mượt, dễ tuỳ biến icon & màu.
    *   Cập nhật `home_screen.dart` để tích hợp component mới.
*   **Bổ sung màn hình Cài đặt (Settings):**
    *   Tạo file `settings_screen.dart` với các mục: Tài khoản, Thông báo, Giao diện, Giới thiệu, Đăng xuất.
    *   Tích hợp với `AuthProvider` để thực thi **logout()**.
    *   Thay thế placeholder "Cài đặt" trong `home_screen.dart` sang `SettingsScreen` thực tế.
*   **Sửa lỗi hình ảnh & phụ thuộc:**
    *   Bắt và xử lý lỗi `HttpException (404)` cho ảnh Unsplash bị xoá.
    *   Gỡ bỏ thư viện **settings_ui** thừa gây lỗi build; xoá import và widget liên quan trong `welcome_screen.dart`.
*   **Quản lý mã nguồn:**
    *   Cập nhật **git**: thêm, commit và chuẩn bị push các thay đổi liên quan đến Settings Screen & Custom Bottom Nav.

### 2. Khó khăn gặp phải

*   Thiết lập kết nối ADB với thiết bị LG gặp nhiều tình huống (driver, cáp USB, tuỳ chọn USB ẩn), tốn thời gian thử nghiệm.
*   Library CurvedNavigationBar giới hạn tùy biến; cần viết lại bằng `CustomPainter` để đạt UI mong muốn.
*   Lỗi hình ảnh 404 từ Unsplash gây crash nếu không có `errorWidget`, yêu cầu xử lý fallback.

### 3. Kế hoạch cho Tuần 4

*   Hoàn thiện chức năng **tạo, xem, cập nhật và xoá (CRUD) Phòng họp** trên Firestore.
*   Đồng bộ **danh sách cuộc họp** realtime với Firebase Cloud Messaging để nhận thông báo.
*   Áp dụng **Dark Mode** & tuỳ chọn Theme từ màn hình Cài đặt.
*   Viết unit test cho `AuthProvider` và widget test cho `CustomBottomNavBar`.
*   Triển khai CI đơn giản (GitHub Actions) chạy `flutter test` và build APK debug mỗi lần push. 