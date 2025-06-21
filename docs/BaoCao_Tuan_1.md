# Báo cáo tiến độ project - Tuần 1

**Thời gian:** Ngày 14/06/2025 

**Sinh viên thực hiện:** Nguyễn Mạnh Cường
**Giảng viên hướng dẫn:** Lê Hoàng Anh

---

### 1. Các công việc đã hoàn thành

*   **Phân tích yêu cầu và thiết kế ý tưởng:**
    *   Xác định mục tiêu chính của ứng dụng: Quản lý cuộc họp.
    *   Phác thảo các tính năng cơ bản cần có: Đăng nhập/Đăng ký, tạo cuộc họp, tham gia cuộc họp, xem lịch sử.
*   **Thiết lập môi trường phát triển:**
    *   Cài đặt Flutter SDK, Visual Studio Code & Android Studio.
    *   Cấu hình máy ảo Android để kiểm thử.
*   **Khởi tạo dự án Flutter:**
    *   Tạo dự án Flutter mới với cấu trúc thư mục tiêu chuẩn.
    *   Tổ chức các thư mục con: `screens`, `components`, `providers`, `constants`.
*   **Xây dựng giao diện người dùng (UI) cơ bản:**
    *   Thiết kế và code giao diện cho màn hình Chào mừng (Welcome Screen).
    *   Thiết kế và code giao diện cho màn hình Đăng nhập (Login Screen).
    *   Thiết kế và code giao diện cho màn hình Đăng ký (Sign Up Screen).
    *   Tạo các thành phần UI có thể tái sử dụng (ví dụ: `Background` widget).
*   **Thiết lập dự án Firebase:**
    *   Tạo dự án mới trên Firebase Console.
    *   Kết nối và cấu hình Firebase cho nền tảng Android.

### 2. Khó khăn gặp phải

*   Mất thời gian ban đầu để làm quen với việc bố cục layout (layouting) trong Flutter sao cho linh hoạt trên nhiều kích thước màn hình.
*   Quá trình cài đặt và cấu hình Android SDK/máy ảo đôi khi gặp các lỗi nhỏ không mong muốn.

### 3. Kế hoạch cho Tuần 2

*   Tích hợp chức năng xác thực người dùng (Authentication) sử dụng Firebase Auth cho màn hình Đăng nhập và Đăng ký.
*   Thiết lập Cloud Firestore để lưu trữ thông tin người dùng.
*   Bắt đầu thiết kế giao diện cho màn hình chính (Home Screen) sau khi đăng nhập thành công.
*   Cấu hình Firebase cho các nền tảng khác (iOS, Web, Desktop) để chuẩn bị cho việc phát triển đa nền tảng. 