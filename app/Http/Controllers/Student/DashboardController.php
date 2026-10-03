<?php

namespace App\Http\Controllers\Student;

use App\Http\Controllers\Controller;
use Illuminate\Support\Facades\Auth;

class DashboardController extends Controller
{
    public function index()
    {
        $student = Auth::user();
        $courses = $student->enrolledCourses()->wherePivot("status", "approved")->get();
        $pendingCoursesCount = $student->pendingCourses()->count();
        $notifications = $student->notifications_app()->take(10)->get();

        return view("student.dashboard", compact("courses", "pendingCoursesCount", "notifications"));
    }
}
