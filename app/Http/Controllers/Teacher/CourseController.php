<?php

namespace App\Http\Controllers\Teacher;

use App\Http\Controllers\Controller;
use App\Models\AppNotification;
use App\Models\Course;
use App\Models\User;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

class CourseController extends Controller
{
    public function dashboard()
    {
        $courses = Auth::user()->coursesTaught()->withCount(["materials", "quizzes", "assignments", "students"])->latest()->get();

        return view("teacher.dashboard", compact("courses"));
    }

    public function create()
    {
        return view("teacher.courses.create");
    }

    public function store(\Illuminate\Http\Request $request)
    {
        $data = $request->validate([
            "title" => ["required", "string", "max:255"],
            "description" => ["nullable", "string"],
        ]);

        $course = Auth::user()->coursesTaught()->create($data);

        return redirect()->route("teacher.courses.show", $course)->with("status", "Course created.");
    }

    public function show(Course $course)
    {
        $this->authorizeCourse($course);

        $course->load(["materials", "syllabus", "quizzes", "assignments", "students", "pendingStudents"]);

        return view("teacher.courses.show", compact("course"));
    }

    /**
     * Approve a student's pending enrollment request.
     */
    public function approveStudent(Course $course, User $student)
    {
        $this->authorizeCourse($course);

        DB::table("course_student")
            ->where("course_id", $course->id)
            ->where("student_id", $student->id)
            ->update(["status" => "approved", "updated_at" => now()]);

        AppNotification::create([
            "user_id" => $student->id,
            "title" => "Enrollment approved: {$course->title}",
            "message" => "Your request to join {$course->title} has been approved. You can now see its quizzes and assignments.",
            "type" => "enrollment",
            "related_id" => $course->id,
        ]);

        return back()->with("status", "Student approved.");
    }

    /**
     * Reject a student's pending enrollment request (removes the request so
     * they are free to request again later).
     */
    public function rejectStudent(Course $course, User $student)
    {
        $this->authorizeCourse($course);

        DB::table("course_student")
            ->where("course_id", $course->id)
            ->where("student_id", $student->id)
            ->where("status", "pending")
            ->delete();

        AppNotification::create([
            "user_id" => $student->id,
            "title" => "Enrollment request declined: {$course->title}",
            "message" => "Your request to join {$course->title} was not approved.",
            "type" => "enrollment",
            "related_id" => $course->id,
        ]);

        return back()->with("status", "Request rejected.");
    }

    /**
     * Remove an already-approved student from the course.
     */
    public function removeStudent(Course $course, User $student)
    {
        $this->authorizeCourse($course);

        DB::table("course_student")
            ->where("course_id", $course->id)
            ->where("student_id", $student->id)
            ->delete();

        return back()->with("status", "Student removed from course.");
    }

    private function authorizeCourse(Course $course): void
    {
        abort_unless($course->teacher_id === Auth::id(), 403);
    }
}
