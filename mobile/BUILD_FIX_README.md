# Hướng dẫn Fix Lỗi Build Flutter

## Vấn đề đã được fix:

### 1. Kotlin Version Incompatibility
- **Trước**: Kotlin 1.7.1 vs Firebase libraries (1.9.0)
- **Sau**: Kotlin 1.9.22 (đồng bộ với Firebase)

### 2. Android Gradle Plugin
- **Trước**: AGP 8.1.4
- **Sau**: AGP 8.2.2 (tương thích với Java 22)

### 3. Gradle Wrapper
- **Trước**: Gradle 8.9
- **Sau**: Gradle 8.5 (tương thích với AGP 8.2.2)

### 4. Java Version
- **Trước**: Java 1.8
- **Sau**: Java 17 (tương thích với AGP 8.2.2)

## Các file đã được cập nhật:

1. `android/build.gradle` - Kotlin version, AGP version
2. `android/app/build.gradle` - Java version, AGP version
3. `android/gradle/wrapper/gradle-wrapper.properties` - Gradle version
4. `android/settings.gradle` - Plugin versions
5. `android/gradle.properties` - Build optimizations

## Cách chạy:

### Phương pháp 1: Sử dụng script
```bash
# Chạy script clean và build
clean_and_build.bat
```

### Phương pháp 2: Thủ công
```bash
# Clean Flutter
flutter clean

# Get dependencies
flutter pub get

# Clean Gradle
cd android
gradlew clean
cd ..

# Run app
flutter run
```

## Lưu ý quan trọng:

1. **Đóng VS Code** trước khi chạy để tránh conflict
2. **Restart máy** nếu vẫn gặp lỗi Gradle cache
3. **Xóa thủ công** thư mục `.gradle` nếu cần:
   - Windows: `%USERPROFILE%\.gradle`
   - Linux/Mac: `~/.gradle`

## Troubleshooting:

### Nếu vẫn gặp lỗi:
1. Kiểm tra Java version: `java -version`
2. Đảm bảo JAVA_HOME trỏ đến Java 17
3. Xóa hoàn toàn Gradle cache
4. Restart máy tính

### Lệnh kiểm tra:
```bash
flutter doctor
flutter doctor -v
java -version
gradle --version
```

## Cấu hình môi trường:

- **Flutter**: 3.x+
- **Dart**: 3.x+
- **Java**: 17
- **Android SDK**: API 34
- **Kotlin**: 1.9.22
- **Gradle**: 8.5
- **Android Gradle Plugin**: 8.2.2 