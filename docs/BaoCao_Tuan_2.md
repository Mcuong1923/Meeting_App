# Báo cáo tiến độ project - Tuần 2

**Thời gian:** Ngày 21/06/2025

**Sinh viên thực hiện:** Nguyễn Mạnh Cường
**Giảng viên hướng dẫn:** Lê Hoàng Anh

---

### 1. Các công việc đã hoàn thành

*   **Tích hợp đa nền tảng (Desktop & Web):**
    *   Kích hoạt và cấu hình dự án để có thể chạy trên nền tảng Windows Desktop và Web.
    *   Cài đặt các công cụ cần thiết cho việc build ứng dụng Windows (Visual Studio với C++ workload).
*   **Gỡ lỗi (Debugging) và xử lý sự cố môi trường:**
    *   **Android:**
        *   Xử lý lỗi xung đột phiên bản `minSdkVersion` và `compileSdkVersion` sau khi nâng cấp các gói phụ thuộc.
        *   Chẩn đoán và khắc phục triệt để lỗi `aapt2.exe` liên quan đến `android.jar` bị hỏng bằng cách cài đặt lại Android SDK Platform 35 và xóa cache của Gradle.
        *   Tạo lại máy ảo Android (AVD) bị lỗi file kernel.
    *   **Web:**
        *   Xử lý sự cố "màn hình trắng" bằng cách chuyển đổi web renderer sang `canvaskit`.
    *   **Firebase:**
        *   Thực hiện nâng cấp các gói `firebase` lên phiên bản mới nhất để xử lý các hàm đã lỗi thời (deprecated).
        *   Chạy lại `flutterfire configure` để cấu hình Firebase cho đầy đủ các nền tảng mới (Web, Windows), giải quyết lỗi `DefaultFirebaseOptions have not been configured`.
        *   Xử lý vấn đề xác thực tài khoản khi dùng Firebase CLI.
*   **Hoàn thiện giao diện:**
    *   Tinh chỉnh lại giao diện màn hình Welcome để tương đồng với các màn hình Login/Sign Up.
    *   Sửa lỗi màu nền và các lỗi cú pháp nhỏ trong code UI.

### 2. Khó khăn gặp phải

*   Quá trình gỡ lỗi môi trường tốn nhiều thời gian hơn dự kiến, đặc biệt là các lỗi liên quan đến Gradle và Android SDK. Điều này cho thấy tầm quan trọng của việc có một môi trường phát triển ổn định.
*   Việc cấu hình Firebase cho nhiều nền tảng đòi hỏi sự cẩn thận và các bước xác thực phức tạp.

### 3. Kế hoạch cho Tuần 3

*   Hoàn thiện chức năng Đăng nhập và Đăng ký bằng email/mật khẩu, kết nối với Firebase Auth.
*   Lưu thông tin người dùng (ngoài email và mật khẩu) vào Cloud Firestore sau khi đăng ký thành công.
*   Xây dựng luồng điều hướng (navigation flow): Sau khi đăng nhập/đăng ký thành công, sẽ chuyển hướng đến màn hình chính của ứng dụng.
*   Bắt đầu xây dựng giao diện cho các chức năng cốt lõi trên màn hình chính. 