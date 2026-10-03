<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class QuizQuestion extends Model
{
    protected $fillable = ["quiz_id", "question_text", "type", "options", "correct_answer", "marks"];

    protected function casts(): array
    {
        return [
            "options" => "array",
        ];
    }

    public function quiz()
    {
        return $this->belongsTo(Quiz::class);
    }
}
