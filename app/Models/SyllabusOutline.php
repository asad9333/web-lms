<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class SyllabusOutline extends Model
{
    protected $fillable = ["course_id", "week_number", "topic", "phase", "is_covered", "covered_at"];

    protected function casts(): array
    {
        return [
            "is_covered" => "boolean",
            "covered_at" => "datetime",
        ];
    }

    public function course()
    {
        return $this->belongsTo(Course::class);
    }
}
