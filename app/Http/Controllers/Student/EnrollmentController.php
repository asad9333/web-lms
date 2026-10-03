<?php

namespace App\Http\Controllers\Student;

use App\Http\Controllers\Controller;
use App\Models\AppNotification;
use App\Models\Course;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

class EnrollmentController extends Controller
{
    public function index()
    {
        $student = Auth::user();

        $enrolledIds = $student->enrolledCourses()->pluck("courses.id");
        $pendingIds = $student->pendingCourses()->pluck("courses.id");

        $availableCourses = Course::with("teacher")
            ->whereNotIn("id", $enrolledIds->merge($pendingIds))
            ->latest()
            ->get();

        $pendingCourses = $student->pendingCourses()->with("teacher")->get();

        return view("student.courses.browse", compact("availableCourses", "pendingCourses"));
    }

    public function store(Course $course)
    {
        $student = Auth::user();

        $alreadyLinked = DB::table("course_student")
            ->where("course_id", $course->id)
            ->where("student_id", $student->id)
            ->exists();

        if ($alreadyLinked) {
            return back()->with("status", "You already have a request or enrollment for this course.");
        }

        DB::table("course_student")->insert([
            "course_id" => $course->id,
            "student_id" => $student->id,
            "status" => "pending",
            "created_at" => now(),
            "updated_at" => now(),
        ]);

        AppNotification::create([
            "user_id" => $course->teacher_id,
            "title" => "New enrollment request: {$course->title}",
            "message" => "{$student->name} ({$student->registration_number}) has requested to join {$course->title}.",
            "type" => "enrollment",
            "related_id" => $course->id,
        ]);

        return back()->with("status", "Enrollment request sent. The teacher will review it.");
    }
}
