<?php

namespace App\Http\Controllers\Student;

use App\Http\Controllers\Controller;
use App\Models\Assignment;
use App\Services\AIGraderService;
use Illuminate\Http\Request;

class AssignmentController extends Controller
{
    public function show(Assignment $assignment)
    {
        $student = auth()->user();
        abort_unless($assignment->course->students->contains($student->id), 403);
        abort_unless($assignment->isOpen(), 403, "This assignment is not currently available.");

        $existing = $assignment->submissions()->where("student_id", $student->id)->first();

        return view("student.assignments.submit", compact("assignment", "existing"));
    }

    public function submit(Request $request, Assignment $assignment, AIGraderService $grader)
    {
        $student = $request->user();
        abort_unless($assignment->course->students->contains($student->id), 403);
        abort_unless($assignment->isOpen(), 403, "This assignment is not currently available.");

        $data = $request->validate([
            "file" => ["required", "file", "mimes:pdf,jpg,jpeg,png,doc,docx", "max:20480"],
        ]);

        $path = $request->file("file")->store("assignment_submissions/{$assignment->id}", "public");

        $submission = $assignment->submissions()->updateOrCreate(
            ["student_id" => $student->id],
            ["file_path" => $path, "submitted_at" => now()]
        );

        $grader->gradeAssignmentSubmission($submission);

        return redirect()->route("student.dashboard")->with("status", "Assignment submitted.");
    }
}
