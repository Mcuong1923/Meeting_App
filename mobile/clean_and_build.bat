@echo off
echo Cleaning Flutter project...
flutter clean

echo Getting Flutter dependencies...
flutter pub get

echo Cleaning Gradle cache...
cd android
gradlew clean
cd ..

echo Building Flutter project...
flutter build apk --debug

echo Done!
pause 