# Course LMS — Setup Guide

Ye zip ek fresh Laravel project (`composer create-project laravel/laravel course-lms`)
ke root folder mein unzip karni hai — sab files apni jagah (app/, database/, resources/, routes/) chali jayengi.

## Setup Steps

1. Fresh Laravel project banao (agar pehle se nahi hai):
   ```
   composer create-project laravel/laravel course-lms
   ```

2. Is zip ko `course-lms` folder ke andar unzip karo (overwrite allow karo).

3. `.env` set karo (DB credentials + storage + AI grading key):
   ```
   DB_CONNECTION=mysql
   DB_DATABASE=course_lms
   DB_USERNAME=root
   DB_PASSWORD=

   ANTHROPIC_API_KEY=sk-ant-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   ANTHROPIC_MODEL=claude-sonnet-5
   ```
   (`.env.example.additions` mein ye do AI lines alag se bhi di hain agar apna existing `.env` merge karna ho.)
   Bina `ANTHROPIC_API_KEY` ke: quizzes ka MCQ/short-answer grading phir bhi automatic chalta rahega (wo local hai),
   sirf assignment AI-grading aur "Generate Draft from Material" button kaam nahi karenge — assignment ko teacher
   manually "Submissions" page se grade kar sakta hai.

4. Register middleware — Laravel 11/12 mein `bootstrap/app.php` mein ye add karo:
   ```php
   ->withMiddleware(function (Middleware $middleware) {
       $middleware->alias([
           "role" => \App\Http\Middleware\EnsureUserHasRole::class,
           "force.password" => \App\Http\Middleware\ForcePasswordChange::class,
       ]);
   })
   ```
   (Laravel 10 ya usse purana ho to `app/Http/Kernel.php` ke `$routeMiddleware` array mein yahi do lines add karo.)

5. Storage link banao (uploaded files ke liye):
   ```
   php artisan storage:link
   ```

6. Migrate + seed admin:
   ```
   php artisan migrate
   php artisan db:seed --class=AdminSeeder
   ```
   Admin login: Registration # `ADMIN-001`, Password `admin123` (pehli baar login pe change karwaya jayega).

7. Serve:
   ```
   php artisan serve
   ```

## Flow

- **Admin** login karke Teachers/Students add karta hai — sirf registration number + name (koi password admin nahi deta/dekhta).
- Naya user pehli baar `/login` par apna **registration number** dalta hai; system pehchanta hai ke iska password abhi tak set nahi hua, seedha "Set Your Password" page pe le jata hai — wahan apna password khud bana kar turant login ho jata hai. Dobara login pe seedha normal password field aayega.
- **Teacher** course banata hai, material upload karta hai (with download link), syllabus week-wise add karta hai
  aur jo topics cover ho chuke hain unhe "covered" mark karta hai.
- Quiz banate waqt teacher chahe to material select kar ke **"Generate Draft from Material"** dabaye —
  AI covered topics ke hisab se questions draft kar deta hai jo teacher edit kar ke save karta hai.
  Manually bhi questions likh sakta hai.
- Teacher jab quiz/assignment generate karta hai, sirf covered topics uske sath save hote hain
  aur enrolled students ko notification chali jati hai (dashboard ke "Notifications" panel mein).
- **Student** open quizzes attempt karta hai (MCQ/short answer submit pe turant auto-check ho jata hai) aur
  assignments file (pdf/image/doc) upload kar ke submit karta hai.
- Assignment submit hote hi AI (Anthropic API) file ko directly padh kar score + feedback assign kar deta hai.
  Teacher **course → Assignments → Submissions** page se har submission ka file khol sakta hai aur
  score/feedback ko override bhi kar sakta hai.

## Optional / not included

- Email/push notifications (abhi sirf in-app `app_notifications` table use ho rahi hai, dashboard pe dikhti hai).
- Result/analytics charts, CSV export.
