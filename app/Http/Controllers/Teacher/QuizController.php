<?php

namespace App\Http\Controllers\Teacher;

use App\Http\Controllers\Controller;
use App\Models\AppNotification;
use App\Models\Course;
use App\Models\CourseMaterial;
use App\Models\Quiz;
use App\Models\QuizSubmission;
use App\Services\AIGraderService;
use App\Services\AIQuizGeneratorService;
use Illuminate\Http\Request;

class QuizController extends Controller
{
    public function create(Course $course)
    {
        abort_unless($course->teacher_id === auth()->id(), 403);

        $coveredTopics = $course->syllabus()->where("is_covered", true)->get();
        $materials = $course->materials()->latest()->get();

        return view("teacher.quizzes.create", compact("course", "coveredTopics", "materials"));
    }

    public function generateDraft(Request $request, Course $course, AIQuizGeneratorService $generator)
    {
        abort_unless($course->teacher_id === $request->user()->id, 403);

        // AI generation (PDF extraction + Gemini, with Groq fallback) can take
        // longer than PHP's default 30s execution limit and use more than the
        // default memory limit — raise both for this request.
        set_time_limit(200);
        ini_set("memory_limit", "1024M");

        $data = $request->validate([
            "material_id" => ["required", "exists:course_materials,id"],
            "range" => ["required", "string", "max:255"],
            "total_marks" => ["required", "integer", "min:1", "max:100"],
            "mix" => ["required", "in:mixed,mcq_only,written_only"],
        ]);

        $material = CourseMaterial::findOrFail($data["material_id"]);
        abort_unless($material->course_id === $course->id, 404);

        try {
            $questions = $generator->draftQuestions(
                $course,
                $material,
                $data["range"],
                $data["total_marks"],
                $data["mix"]
            );
        } catch (\Throwable $e) {
            return response()->json(["error" => $e->getMessage()], 422);
        }

        return response()->json(["questions" => $questions]);
    }

    public function store(Request $request, Course $course)
    {
        abort_unless($course->teacher_id === $request->user()->id, 403);

        $data = $request->validate([
            "title" => ["required", "string", "max:255"],
            "available_from" => ["required", "date"],
            "available_until" => ["required", "date", "after:available_from"],
            "questions" => ["required", "array", "min:1"],
            "questions.*.question_text" => ["required", "string"],
            "questions.*.type" => ["required", "in:mcq,short"],
            "questions.*.options" => ["nullable", "array"],
            "questions.*.correct_answer" => ["required", "string"],
            "questions.*.marks" => ["required", "integer", "min:1"],
        ]);

        $coveredTopics = $course->syllabus()->where("is_covered", true)->pluck("topic")->implode(", ");
        $totalMarks = collect($data["questions"])->sum("marks");

        $quiz = $course->quizzes()->create([
            "title" => $data["title"],
            "topics_covered" => $coveredTopics,
            "total_marks" => $totalMarks,
            "available_from" => $data["available_from"],
            "available_until" => $data["available_until"],
        ]);

        foreach ($data["questions"] as $question) {
            $quiz->questions()->create($question);
        }

        foreach ($course->students as $student) {
            AppNotification::create([
                "user_id" => $student->id,
                "title" => "New quiz: {$quiz->title}",
                "message" => "A new quiz is available for {$course->title}. It closes on {$quiz->available_until}.",
                "type" => "quiz",
                "related_id" => $quiz->id,
            ]);
        }

        return redirect()->route("teacher.courses.show", $course)->with("status", "Quiz created and students notified.");
    }

    public function results(Course $course, Quiz $quiz)
    {
        abort_unless($course->teacher_id === auth()->id(), 403);
        abort_unless($quiz->course_id === $course->id, 404);

        $quiz->load("submissions.student");

        return view("teacher.quizzes.results", compact("course", "quiz"));
    }

    /**
     * Run AI grading on a single quiz submission (or re-run it, overwriting
     * the previous score/checked_at).
     */
    public function aiCheck(Course $course, Quiz $quiz, QuizSubmission $submission, AIGraderService $grader)
    {
        abort_unless($course->teacher_id === auth()->id(), 403);
        abort_unless($quiz->course_id === $course->id, 404);
        abort_unless($submission->quiz_id === $quiz->id, 404);

        set_time_limit(200);
        ini_set("memory_limit", "1024M");

        try {
            $grader->gradeQuizSubmission($submission);
        } catch (\Throwable $e) {
            return back()->with("status", "AI check failed: " . $e->getMessage());
        }

        return back()->with("status", "Submission checked with AI.");
    }

    /**
     * Run AI grading on every ungraded submission for this quiz.
     */
    public function aiCheckAll(Course $course, Quiz $quiz, AIGraderService $grader)
    {
        abort_unless($course->teacher_id === auth()->id(), 403);
        abort_unless($quiz->course_id === $course->id, 404);

        set_time_limit(200);
        ini_set("memory_limit", "1024M");

        $submissions = $quiz->submissions()->whereNull("checked_at")->get();
        $checked = 0;
        $failed = 0;

        foreach ($submissions as $submission) {
            try {
                $grader->gradeQuizSubmission($submission);
                $checked++;
            } catch (\Throwable $e) {
                $failed++;
            }
        }

        $message = "{$checked} submission(s) checked with AI.";
        if ($failed) {
            $message .= " {$failed} failed — you can check those individually.";
        }

        return back()->with("status", $message);
    }
}
