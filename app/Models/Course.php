<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Course extends Model
{
    protected $fillable = ["teacher_id", "title", "description"];

    public function teacher()
    {
        return $this->belongsTo(User::class, "teacher_id");
    }

    /**
     * Students who have been approved into the course.
     */
    public function students()
    {
        return $this->belongsToMany(User::class, "course_student", "course_id", "student_id")
            ->wherePivot("status", "approved")
            ->withPivot("status")
            ->withTimestamps();
    }

    /**
     * Students who have requested to join and are awaiting teacher approval.
     */
    public function pendingStudents()
    {
        return $this->belongsToMany(User::class, "course_student", "course_id", "student_id")
            ->wherePivot("status", "pending")
            ->withPivot("status")
            ->withTimestamps();
    }

    public function materials()
    {
        return $this->hasMany(CourseMaterial::class);
    }

    public function syllabus()
    {
        return $this->hasMany(SyllabusOutline::class)->orderBy("week_number");
    }

    public function quizzes()
    {
        return $this->hasMany(Quiz::class);
    }

    public function assignments()
    {
        return $this->hasMany(Assignment::class);
    }

    public function coveredTopicsSummary(): string
    {
        return $this->syllabus()->where("is_covered", true)->pluck("topic")->implode(", ");
    }
}
