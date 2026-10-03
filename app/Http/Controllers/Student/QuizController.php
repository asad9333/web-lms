<?php

namespace App\Http\Controllers\Student;

use App\Http\Controllers\Controller;
use App\Models\Quiz;
use App\Services\AIGraderService;
use Illuminate\Http\Request;

class QuizController extends Controller
{
    public function show(Quiz $quiz)
    {
        $student = auth()->user();
        abort_unless($quiz->course->students->contains($student->id), 403);
        abort_unless($quiz->isOpen(), 403, "This quiz is not currently available.");

        $existing = $quiz->submissions()->where("student_id", $student->id)->first();

        return view("student.quizzes.attempt", compact("quiz", "existing"));
    }

    public function submit(Request $request, Quiz $quiz, AIGraderService $grader)
    {
        $student = $request->user();
        abort_unless($quiz->course->students->contains($student->id), 403);
        abort_unless($quiz->isOpen(), 403, "This quiz is not currently available.");

        $data = $request->validate([
            "answers" => ["required", "array"],
        ]);

        $submission = $quiz->submissions()->updateOrCreate(
            ["student_id" => $student->id],
            ["answers" => $data["answers"], "submitted_at" => now()]
        );

        $grader->gradeQuizSubmission($submission);

        return redirect()->route("student.dashboard")->with("status", "Quiz submitted. Result will appear once checked.");
    }
}
