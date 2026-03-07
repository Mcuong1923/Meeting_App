# Firebase Configuration Check Guide

## Cách kiểm tra Firebase Project ID

### Bước 1: Chạy app và xem log

Sau khi thêm log vào `main.dart`, khi bạn chạy app sẽ thấy output như sau:

```
═══════════════════════════════════════════════════════════
🔥 FIREBASE CONFIGURATION CHECK
═══════════════════════════════════════════════════════════
🔥 Firebase App Name: [DEFAULT]
🔥 Firebase Project ID: mettingapp-aef60
🔥 Firebase Database URL: https://mettingapp-aef60-default-rtdb.firebaseio.com
🔥 Firebase API Key: AIzaSyCikO3...
🔥 Firebase App ID: 1:959832172654:android:5e378f6d9ad32edb58de7f
🔥 Firebase Storage Bucket: mettingapp-aef60.firebasestorage.app
═══════════════════════════════════════════════════════════
📋 So sánh với Firebase Console:
   1. Vào Firebase Console → Project Settings
   2. Kiểm tra Project ID có khớp với giá trị trên không
═══════════════════════════════════════════════════════════
```

### Bước 2: So sánh với Firebase Console

1. Mở [Firebase Console](https://console.firebase.google.com/)
2. Chọn project của bạn
3. Vào **Project Settings** (⚙️ icon ở góc trên bên trái)
4. Trong tab **General**, tìm **Project ID**
5. So sánh với giá trị trong log console

### Bước 3: Verify

✅ **Đúng nếu:**
- Project ID trong log khớp với Project ID trong Firebase Console
- Database URL có format: `https://[project-id]-default-rtdb.firebaseio.com`

❌ **Sai nếu:**
- Project ID không khớp
- Database URL khác
- Có lỗi khi initialize Firebase

## Logs được thêm vào:

1. **main.dart**: Log khi app khởi động (sau `Firebase.initializeApp()`)
2. **meeting_provider.dart**: Log khi MeetingProvider được tạo

## Troubleshooting

### Nếu Project ID không khớp:

1. Kiểm tra file `firebase_options.dart`:
   ```dart
   static const FirebaseOptions android = FirebaseOptions(
     projectId: 'mettingapp-aef60', // ← Kiểm tra giá trị này
     ...
   );
   ```

2. Regenerate Firebase config:
   ```bash
   flutterfire configure
   ```

3. Hoặc manually update `firebase_options.dart` với project ID đúng

### Nếu không thấy log:

1. Đảm bảo app đã chạy: `flutter run`
2. Check console output (không phải debug console)
3. Nếu dùng VS Code, check "Debug Console" tab

## Expected Output

Khi app chạy đúng, bạn sẽ thấy:

```
🔥 Firebase Project ID: mettingapp-aef60
```

Và trong Firebase Console → Project Settings → General:
- **Project ID**: `mettingapp-aef60` (phải khớp)

## Sau khi verify xong

Nếu đã confirm đúng Firebase project, bạn có thể:
1. Giữ log này để debug sau này
2. Hoặc remove log nếu không cần thiết (nhưng nên giữ để debug)
