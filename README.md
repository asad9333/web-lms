# Course LMS (Flutter - standalone)

Web (Laravel) LMS ka standalone Flutter version. Server / web ki zaroorat nahi:
data SQLite me device par save hota hai.

## Setup (sirf pehli baar)
1. Is folder me `setup.bat` double-click karo (ya terminal me `setup.bat`).
2. Phone/emulator par chalane ke liye: `flutter run`
3. Installable APK: `flutter build apk --release`
   -> `build\app\outputs\flutter-apk\app-release.apk`

## Default login
- Registration number: `ADMIN-001`
- Pehli baar login par app khud naya password set karwayegi.

## Roles
- **Admin**: teachers/students banata hai, password reset, user remove.
- **Teacher**: courses, materials (PDF/DOC/PPT), syllabus, quizzes, assignments, student approve/reject, AI draft + AI check.
- **Student**: courses browse + join request, quiz attempt, assignment submit, results + notifications.

## AI features
Admin/Teacher menu (top-right) > **AI Settings** me Gemini / Groq API key daalo.
AI draft/grading ke liye internet chahiye; baqi app poori offline chalti hai.

## Note
Ye app single-device standalone hai: har phone ka data alag hota hai
(teacher aur students ka real-time sync tabhi hoga jab server add kiya jaye).
