<?php

use App\Http\Controllers\Admin\UserController as AdminUserController;
use App\Http\Controllers\Auth\LoginController;
use App\Http\Controllers\Auth\PasswordController;
use App\Http\Controllers\Student\AssignmentController as StudentAssignmentController;
use App\Http\Controllers\Student\CourseController as StudentCourseController;
use App\Http\Controllers\Student\DashboardController as StudentDashboardController;
use App\Http\Controllers\Student\EnrollmentController as StudentEnrollmentController;
use App\Http\Controllers\Student\QuizController as StudentQuizController;
use App\Http\Controllers\Teacher\AssignmentController as TeacherAssignmentController;
use App\Http\Controllers\Teacher\CourseController;
use App\Http\Controllers\Teacher\MaterialController;
use App\Http\Controllers\Teacher\QuizController as TeacherQuizController;
use App\Http\Controllers\Teacher\SyllabusController;
use Illuminate\Support\Facades\Route;

Route::get("/", fn () => redirect()->route("login"));

Route::get("/login", [LoginController::class, "showStep1"])->name("login");
Route::post("/login/continue", [LoginController::class, "checkRegistration"])->name("login.continue");
Route::get("/login/password", [LoginController::class, "showPasswordStep"])->name("login.password");
Route::post("/login/password", [LoginController::class, "login"])->name("login.password.submit");
Route::get("/login/set-password", [LoginController::class, "showSetupPassword"])->name("login.setup-password");
Route::post("/login/set-password", [LoginController::class, "storeSetupPassword"])->name("login.setup-password.submit");
Route::post("/logout", [LoginController::class, "logout"])->name("logout");

Route::middleware("auth")->group(function () {
    Route::get("/change-password", [PasswordController::class, "show"])->name("password.change");
    Route::post("/change-password", [PasswordController::class, "update"])->name("password.update");
});

Route::middleware(["auth", "force.password", "role:admin"])->prefix("admin")->name("admin.")->group(function () {
    Route::get("/dashboard", [AdminUserController::class, "dashboard"])->name("dashboard");
    Route::get("/users", [AdminUserController::class, "index"])->name("users.index");
    Route::get("/users/create", [AdminUserController::class, "create"])->name("users.create");
    Route::post("/users", [AdminUserController::class, "store"])->name("users.store");
    Route::post("/users/{user}/reset-password", [AdminUserController::class, "resetPassword"])->name("users.reset-password");
    Route::delete("/users/{user}", [AdminUserController::class, "destroy"])->name("users.destroy");
});

Route::middleware(["auth", "force.password", "role:teacher"])->prefix("teacher")->name("teacher.")->group(function () {
    Route::get("/dashboard", [CourseController::class, "dashboard"])->name("dashboard");
    Route::get("/courses/create", [CourseController::class, "create"])->name("courses.create");
    Route::post("/courses", [CourseController::class, "store"])->name("courses.store");
    Route::get("/courses/{course}", [CourseController::class, "show"])->name("courses.show");

    Route::post("/courses/{course}/students/{student}/approve", [CourseController::class, "approveStudent"])->name("courses.students.approve");
    Route::post("/courses/{course}/students/{student}/reject", [CourseController::class, "rejectStudent"])->name("courses.students.reject");
    Route::delete("/courses/{course}/students/{student}", [CourseController::class, "removeStudent"])->name("courses.students.remove");

    Route::post("/courses/{course}/materials", [MaterialController::class, "store"])->name("materials.store");
    Route::delete("/courses/{course}/materials/{material}", [MaterialController::class, "destroy"])->name("materials.destroy");

    Route::post("/courses/{course}/syllabus", [SyllabusController::class, "store"])->name("syllabus.store");
    Route::post("/courses/{course}/syllabus/{syllabusOutline}/cover", [SyllabusController::class, "markCovered"])->name("syllabus.cover");

    Route::get("/courses/{course}/quizzes/create", [TeacherQuizController::class, "create"])->name("quizzes.create");
    Route::post("/courses/{course}/quizzes/generate-draft", [TeacherQuizController::class, "generateDraft"])->name("quizzes.generate-draft");
    Route::post("/courses/{course}/quizzes", [TeacherQuizController::class, "store"])->name("quizzes.store");
    Route::get("/courses/{course}/quizzes/{quiz}/results", [TeacherQuizController::class, "results"])->name("quizzes.results");
    Route::post("/courses/{course}/quizzes/{quiz}/submissions/{submission}/ai-check", [TeacherQuizController::class, "aiCheck"])->name("quizzes.submissions.ai-check");
    Route::post("/courses/{course}/quizzes/{quiz}/ai-check-all", [TeacherQuizController::class, "aiCheckAll"])->name("quizzes.ai-check-all");

    Route::get("/courses/{course}/assignments/create", [TeacherAssignmentController::class, "create"])->name("assignments.create");
    Route::post("/courses/{course}/assignments/generate-draft", [TeacherAssignmentController::class, "generateDraft"])->name("assignments.generate-draft");
    Route::post("/courses/{course}/assignments", [TeacherAssignmentController::class, "store"])->name("assignments.store");
    Route::get("/courses/{course}/assignments/{assignment}/submissions", [TeacherAssignmentController::class, "submissions"])->name("assignments.submissions");
    Route::post("/courses/{course}/assignment-submissions/{submission}/grade", [TeacherAssignmentController::class, "grade"])->name("assignments.grade");
    Route::post("/courses/{course}/assignments/{assignment}/submissions/{submission}/ai-check", [TeacherAssignmentController::class, "aiCheck"])->name("assignments.submissions.ai-check");
    Route::post("/courses/{course}/assignments/{assignment}/ai-check-all", [TeacherAssignmentController::class, "aiCheckAll"])->name("assignments.ai-check-all");
});

Route::middleware(["auth", "force.password", "role:student"])->prefix("student")->name("student.")->group(function () {
    Route::get("/dashboard", [StudentDashboardController::class, "index"])->name("dashboard");

    Route::get("/courses/browse", [StudentEnrollmentController::class, "index"])->name("courses.browse");
    Route::post("/courses/{course}/request-enrollment", [StudentEnrollmentController::class, "store"])->name("courses.request-enrollment");
    Route::get("/courses/{course}", [StudentCourseController::class, "show"])->name("courses.show");

    Route::get("/quizzes/{quiz}", [StudentQuizController::class, "show"])->name("quizzes.show");
    Route::post("/quizzes/{quiz}", [StudentQuizController::class, "submit"])->name("quizzes.submit");

    Route::get("/assignments/{assignment}", [StudentAssignmentController::class, "show"])->name("assignments.show");
    Route::post("/assignments/{assignment}", [StudentAssignmentController::class, "submit"])->name("assignments.submit");
});
