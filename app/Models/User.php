<?php

namespace App\Models;

use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;

class User extends Authenticatable
{
    use HasFactory, Notifiable;

    protected $fillable = [
        "registration_number",
        "name",
        "email",
        "password",
        "role",
        "must_change_password",
    ];

    protected $hidden = [
        "password",
        "remember_token",
    ];

    protected function casts(): array
    {
        return [
            "must_change_password" => "boolean",
        ];
    }

    public function isAdmin(): bool
    {
        return $this->role === "admin";
    }

    public function isTeacher(): bool
    {
        return $this->role === "teacher";
    }

    public function isStudent(): bool
    {
        return $this->role === "student";
    }

    public function coursesTaught()
    {
        return $this->hasMany(Course::class, "teacher_id");
    }

    /**
     * Courses this student has been approved into.
     */
    public function enrolledCourses()
    {
        return $this->belongsToMany(Course::class, "course_student", "student_id", "course_id")
            ->wherePivot("status", "approved")
            ->withPivot("status")
            ->withTimestamps();
    }

    /**
     * Courses this student has requested to join and is awaiting approval for.
     */
    public function pendingCourses()
    {
        return $this->belongsToMany(Course::class, "course_student", "student_id", "course_id")
            ->wherePivot("status", "pending")
            ->withPivot("status")
            ->withTimestamps();
    }

    public function quizSubmissions()
    {
        return $this->hasMany(QuizSubmission::class, "student_id");
    }

    public function assignmentSubmissions()
    {
        return $this->hasMany(AssignmentSubmission::class, "student_id");
    }

    public function notifications_app()
    {
        return $this->hasMany(AppNotification::class, "user_id")->latest();
    }
}
