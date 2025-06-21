# Ứng dụng Quản lý Cuộc họp (Meeting App)

Đây là dự án thực tập tốt nghiệp phát triển ứng dụng quản lý cuộc họp đa nền tảng (Mobile, Web, Desktop) sử dụng Flutter và Firebase.

## ✨ Tính năng chính

*   **🔐 Xác thực người dùng:** Đăng ký, đăng nhập, phân quyền người dùng an toàn bằng Email/Mật khẩu.
*   **📅 Lập lịch cuộc họp:** Tạo, chỉnh sửa, xóa lịch họp với thông tin chi tiết (thời gian, địa điểm, người tham gia).
*   **📋 Quản lý agenda cuộc họp:** Tạo và quản lý chương trình nghị sự cho từng cuộc họp.
*   **🔔 Hệ thống thông báo tự động:** Gửi thông báo nhắc nhở cuộc họp, cập nhật lịch trình.
*   **📝 Ghi chép biên bản cuộc họp:** Tạo và lưu trữ biên bản cuộc họp với khả năng chỉnh sửa.
*   **📁 Chia sẻ và quản lý tệp:** Upload, chia sẻ tài liệu liên quan đến cuộc họp.
*   **🔍 Tìm kiếm thông minh:** Tìm kiếm cuộc họp, tài liệu, biên bản theo nhiều tiêu chí.

## 🚀 Công nghệ sử dụng

*   **Frontend:** [Flutter](https://flutter.dev/) - Framework phát triển giao diện người dùng đa nền tảng.
*   **Backend & Cơ sở dữ liệu:** [Firebase](https://firebase.google.com/)
    *   **Firebase Authentication:** Xử lý xác thực người dùng.
    *   **Cloud Firestore:** Lưu trữ dữ liệu về người dùng, cuộc họp, tin nhắn.
    *   **Firebase Storage:** (Dự kiến) Lưu trữ tài liệu, ảnh đại diện.
*   **Ngôn ngữ:** [Dart](https://dart.dev/)
*   **Quản lý trạng thái:** [Provider](https://pub.dev/packages/provider)

## 📂 Cấu trúc dự án

Dự án được tổ chức theo cấu trúc rõ ràng để dễ dàng quản lý và mở rộng.

```
METTING_APP/
├── mobile/                  # Chứa toàn bộ source code của ứng dụng Flutter
│   ├── lib/
│   │   ├── components/      # Các widget UI có thể tái sử dụng
│   │   ├── constants.dart   # Các hằng số (màu sắc, styles...)
│   │   ├── models/          # (Dự kiến) Các lớp model dữ liệu
│   │   ├── providers/       # Quản lý trạng thái và logic nghiệp vụ
│   │   ├── resources/       # (Dự kiến) Quản lý tài nguyên, API
│   │   ├── screens/         # Các màn hình chính của ứng dụng
│   │   └── main.dart        # Điểm khởi đầu của ứng dụng
│   ├── pubspec.yaml         # Quản lý các gói phụ thuộc
│   └── ...
├── docs/                    # Chứa tài liệu, báo cáo tiến độ
│   ├── BaoCao_Tuan_1.md
│   └── BaoCao_Tuan_2.md
|   |__ ............
└── README.md                
```

## ⚙️ Hướng dẫn cài đặt và chạy dự án

Làm theo các bước dưới đây để chạy dự án trên máy của bạn.

### **Yêu cầu hệ thống**
*   Cài đặt **Flutter SDK** (phiên bản 3.19.0 trở lên). Hướng dẫn tại [đây](https://docs.flutter.dev/get-started/install).
*   Cài đặt **Visual Studio Code** hoặc **Android Studio**.
*   Cài đặt **Git** để quản lý phiên bản.

### **Các bước thực hiện**
1.  **Clone repository về máy:**
    ```bash
    git clone [URL_REPOSITORY]
    ```

2.  **Di chuyển vào thư mục dự án Flutter:**
    ```bash
    cd METTING_APP/mobile
    ```

3.  **Cài đặt các gói phụ thuộc:**
    *Lệnh này sẽ tải về tất cả các thư viện được định nghĩa trong `pubspec.yaml`.*
    ```bash
    flutter pub get
    ```

4.  **Chạy ứng dụng:**
    *   Mở một máy ảo (Android/iOS) hoặc kết nối thiết bị thật.
    *   Bạn cũng có thể chọn target là Web hoặc Desktop (Windows/macOS/Linux).

    *Chạy ứng dụng với lệnh:*
    ```bash
    flutter run
    ```

    *Để chọn một thiết bị cụ thể (ví dụ: chrome), dùng lệnh:*
    ```bash
    flutter run -d chrome
    ```

## 🗓️ Lịch trình phát triển (Dự kiến)

| Tuần       | Giai đoạn                  | Mục tiêu chính                                                                  |
| :--------- | :------------------------- | :------------------------------------------------------------------------------ |
| **Tuần 1-2** | **Khởi tạo & Giao diện**   | Cài đặt môi trường, tạo dự án, xây dựng UI cho các màn hình Welcome, Login, Sign Up. |
| **Tuần 3-4** | **Xác thực & Cơ sở dữ liệu** | Tích hợp Firebase Auth, lưu thông tin người dùng với Firestore, thiết lập phân quyền. |
| **Tuần 5-6** | **Lập lịch cuộc họp**      | Xây dựng tính năng tạo, chỉnh sửa, xóa lịch họp với thông tin chi tiết. |
| **Tuần 7-8** | **Quản lý Agenda & Biên bản** | Phát triển tính năng quản lý chương trình nghị sự và ghi chép biên bản cuộc họp. |
| **Tuần 9-10**| **Thông báo & Chia sẻ tệp** | Tích hợp hệ thống thông báo tự động và tính năng upload/chia sẻ tài liệu. |
| **Tuần 11-12**| **Tìm kiếm & Hoàn thiện** | Xây dựng tính năng tìm kiếm thông minh, tối ưu hiệu năng, kiểm thử toàn diện. |

---
Liên Hệ
Email:nvancuong792@gmail.com
github:@Mcuong1923