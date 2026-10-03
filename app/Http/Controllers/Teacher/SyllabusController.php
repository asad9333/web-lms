<?php

namespace App\Http\Controllers\Teacher;

use App\Http\Controllers\Controller;
use App\Models\Course;
use Illuminate\Http\Request;

class SyllabusController extends Controller
{
    public function store(Request $request, Course $course)
    {
        abort_unless($course->teacher_id === $request->user()->id, 403);

        $data = $request->validate([
            "week_number" => ["required", "integer", "min:1"],
            "topic" => ["required", "string", "max:255"],
            "phase" => ["required", "in:before_mid,before_final"],
        ]);

        $course->syllabus()->create($data);

        return back()->with("status", "Syllabus item added.");
    }

    public function markCovered(Request $request, Course $course, \App\Models\SyllabusOutline $syllabusOutline)
    {
        abort_unless($course->teacher_id === $request->user()->id, 403);
        abort_unless($syllabusOutline->course_id === $course->id, 404);

        $syllabusOutline->update([
            "is_covered" => true,
            "covered_at" => now(),
        ]);

        return back()->with("status", "Marked as covered.");
    }
}
