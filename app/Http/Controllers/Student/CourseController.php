<?php

namespace App\Http\Controllers\Student;

use App\Http\Controllers\Controller;
use App\Models\Course;
use Illuminate\Support\Facades\Auth;

class CourseController extends Controller
{
    public function show(Course $course)
    {
        $student = Auth::user();

        $enrolled = $student->enrolledCourses()
            ->wherePivot("status", "approved")
            ->where("courses.id", $course->id)
            ->exists();

        abort_unless($enrolled, 403);

        $course->load(["quizzes", "assignments"]);

        $gradedQuizzes = $student->quizSubmissions()
            ->whereNotNull("checked_at")
            ->whereHas("quiz", fn ($q) => $q->where("course_id", $course->id))
            ->with("quiz")
            ->latest("checked_at")
            ->get();

        $gradedAssignments = $student->assignmentSubmissions()
            ->whereNotNull("checked_at")
            ->whereHas("assignment", fn ($q) => $q->where("course_id", $course->id))
            ->with("assignment")
            ->latest("checked_at")
            ->get();

        return view("student.courses.show", compact("course", "gradedQuizzes", "gradedAssignments"));
    }
}
