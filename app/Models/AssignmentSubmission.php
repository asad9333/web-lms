<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AssignmentSubmission extends Model
{
    protected $fillable = ["assignment_id", "student_id", "file_path", "score", "feedback", "submitted_at", "checked_at"];

    protected function casts(): array
    {
        return [
            "submitted_at" => "datetime",
            "checked_at" => "datetime",
        ];
    }

    public function assignment()
    {
        return $this->belongsTo(Assignment::class);
    }

    public function student()
    {
        return $this->belongsTo(User::class, "student_id");
    }
}
