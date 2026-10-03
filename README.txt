HOW TO USE THIS ZIP
====================

1. Extract this zip directly INSIDE your Laravel project's root folder
   (the folder that has "app", "routes", "config" etc. in it — same
   level as your existing artisan file). Let it MERGE/overwrite the
   existing folders — say "Yes to all" if Windows asks about replacing
   files.

2. After extracting, run these commands from your project root:

   composer require smalot/pdfparser
   php artisan migrate
   php artisan route:clear
   php artisan config:clear
   php artisan cache:clear

3. Make sure your .env has these (Gemini + Groq fallback):

   GEMINI_API_KEY=your_gemini_key
   GEMINI_MODEL=gemini-3.6-flash
   GROQ_API_KEY=your_groq_key
   GROQ_MODEL=llama-3.3-70b-versatile

4. Restart the dev server:

   php artisan serve

WHAT'S INCLUDED
================
- app/Models/Course.php, User.php               -> approved/pending student relations
- app/Http/Controllers/Teacher/CourseController.php -> approve/reject/remove students
- app/Http/Controllers/Teacher/QuizController.php       -> AI draft + AI check/check-all for quiz submissions
- app/Http/Controllers/Teacher/AssignmentController.php -> AI draft + AI check/check-all for assignment submissions
- resources/views/teacher/quizzes/results.blade.php     -> NEW: Check with AI / Check All buttons
- resources/views/teacher/assignments/submissions.blade.php -> NEW: Check with AI / Check All buttons
- app/Http/Controllers/Student/DashboardController.php  -> pending count
- app/Http/Controllers/Student/EnrollmentController.php -> NEW: browse/request courses
- app/Services/AIProviderClient.php              -> Gemini -> Groq fallback, PDF text extraction
- app/Services/AIQuizGeneratorService.php         -> quiz draft generator
- app/Services/AIAssignmentGeneratorService.php   -> assignment draft generator
- app/Services/AIGraderService.php                -> AI grading (quiz short answers + assignments)
- config/services.php                             -> gemini/groq config
- routes/web.php                                  -> full route list incl. new enrollment routes
- database/migrations/..._add_status_to_course_student_table.php -> pending/approved status
- resources/views/teacher/courses/show.blade.php  -> redesigned Students tab
- resources/views/teacher/assignments/create.blade.php -> AI draft section added
- resources/views/student/dashboard.blade.php     -> Browse Courses button + pending badge
- resources/views/student/courses/browse.blade.php -> NEW: request-to-join page
