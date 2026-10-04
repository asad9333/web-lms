@echo off
echo ==============================================
echo   Course LMS - one time setup
echo ==============================================

echo.
echo [1/4] Creating Android project files...
call flutter create --platforms=android --project-name course_lms_app --org com.courselms .
if errorlevel 1 goto fail

echo.
echo [2/4] Getting packages...
call flutter pub get
if errorlevel 1 goto fail

echo.
echo [3/4] Generating app icon...
call dart run flutter_launcher_icons
if errorlevel 1 goto fail

echo.
echo [4/4] Setting app name + internet permission...
call dart run tool/patch_android.dart
if errorlevel 1 goto fail

echo.
echo ==============================================
echo   Setup complete.
echo   Test on phone/emulator :  flutter run
echo   Build installable APK  :  flutter build apk --release
echo   APK location           :  build\app\outputs\flutter-apk\app-release.apk
echo ==============================================
goto end

:fail
echo.
echo Setup failed. Please copy the error above and send it.

:end
pause
