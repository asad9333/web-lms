<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Quiz extends Model
{
    protected $fillable = ["course_id", "title", "topics_covered", "total_marks", "available_from", "available_until"];

    protected function casts(): array
    {
        return [
            "available_from" => "datetime",
            "available_until" => "datetime",
        ];
    }

    public function course()
    {
        return $this->belongsTo(Course::class);
    }

    public function questions()
    {
        return $this->hasMany(QuizQuestion::class);
    }

    public function submissions()
    {
        return $this->hasMany(QuizSubmission::class);
    }

    public function isOpen(): bool
    {
        $now = now();
        return $now->between($this->available_from, $this->available_until);
    }
}
