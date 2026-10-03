<?php

namespace App\Http\Controllers\Teacher;

use App\Http\Controllers\Controller;
use App\Models\AppNotification;
use App\Models\Assignment;
use App\Models\AssignmentSubmission;
use App\Models\Course;
use App\Models\CourseMaterial;
use App\Services\AIAssignmentGeneratorService;
use App\Services\AIGraderService;
use Illuminate\Http\Request;

class AssignmentController extends Controller
{
    public function create(Course $course)
    {
        abort_unless($course->teacher_id === auth()->id(), 403);

        $materials = $course->materials()->latest()->get();

        return view("teacher.assignments.create", compact("course", "materials"));
    }

    public function generateDraft(Request $request, Course $course, AIAssignmentGeneratorService $generator)
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
        ]);

        $material = CourseMaterial::findOrFail($data["material_id"]);
        abort_unless($material->course_id === $course->id, 404);

        try {
            $draft = $generator->draftAssignment(
                $course,
                $material,
                $data["range"],
                $data["total_marks"]
            );
        } catch (\Throwable $e) {
            return response()->json(["error" => $e->getMessage()], 422);
        }

        return response()->json($draft);
    }

    public function store(Request $request, Course $course)
    {
        abort_unless($course->teacher_id === $request->user()->id, 403);

        $data = $request->validate([
            "title" => ["required", "string", "max:255"],
            "description" => ["nullable", "string"],
            "total_marks" => ["required", "integer", "min:1"],
            "available_from" => ["required", "date"],
            "available_until" => ["required", "date", "after:available_from"],
        ]);

        $coveredTopics = $course->syllabus()->where("is_covered", true)->pluck("topic")->implode(", ");

        $assignment = $course->assignments()->create([
            ...$data,
            "topics_covered" => $coveredTopics,
        ]);

        foreach ($course->students as $student) {
            AppNotification::create([
                "user_id" => $student->id,
                "title" => "New assignment: {$assignment->title}",
                "message" => "A new assignment is available for {$course->title}. Due {$assignment->available_until}.",
                "type" => "assignment",
                "related_id" => $assignment->id,
            ]);
        }

        return redirect()->route("teacher.courses.show", $course)->with("status", "Assignment created and students notified.");
    }

    public function submissions(Course $course, Assignment $assignment)
    {
        abort_unless($course->teacher_id === auth()->id(), 403);
        abort_unless($assignment->course_id === $course->id, 404);

        $assignment->load("submissions.student");

        return view("teacher.assignments.submissions", compact("course", "assignment"));
    }

    public function grade(Request $request, Course $course, AssignmentSubmission $submission)
    {
        abort_unless($course->teacher_id === $request->user()->id, 403);

        $data = $request->validate([
            "score" => ["required", "integer", "min:0"],
            "feedback" => ["nullable", "string"],
        ]);

        $submission->update([
            ...$data,
            "checked_at" => now(),
        ]);

        return back()->with("status", "Grade saved.");
    }

    /**
     * Run AI grading on a single assignment submission (or re-run it,
     * overwriting the previous score/feedback/checked_at).
     */
    public function aiCheck(Course $course, Assignment $assignment, AssignmentSubmission $submission, AIGraderService $grader)
    {
        abort_unless($course->teacher_id === auth()->id(), 403);
        abort_unless($assignment->course_id === $course->id, 404);
        abort_unless($submission->assignment_id === $assignment->id, 404);

        set_time_limit(200);
        ini_set("memory_limit", "1024M");

        try {
            $grader->gradeAssignmentSubmission($submission);
        } catch (\Throwable $e) {
            return back()->with("status", "AI check failed: " . $e->getMessage());
        }

        if (! $submission->fresh()->checked_at) {
            return back()->with("status", "AI could not grade this submission automatically (unsupported file type or no response) — please grade it manually below.");
        }

        return back()->with("status", "Submission checked with AI.");
    }

    /**
     * Run AI grading on every ungraded submission for this assignment.
     */
    public function aiCheckAll(Course $course, Assignment $assignment, AIGraderService $grader)
    {
        abort_unless($course->teacher_id === auth()->id(), 403);
        abort_unless($assignment->course_id === $course->id, 404);

        set_time_limit(200);
        ini_set("memory_limit", "1024M");

        $submissions = $assignment->submissions()->whereNull("checked_at")->get();
        $checked = 0;
        $failed = 0;

        foreach ($submissions as $submission) {
            try {
                $grader->gradeAssignmentSubmission($submission);
                $submission->fresh()->checked_at ? $checked++ : $failed++;
            } catch (\Throwable $e) {
                $failed++;
            }
        }

        $message = "{$checked} submission(s) checked with AI.";
        if ($failed) {
            $message .= " {$failed} need manual grading (unsupported file type or AI error).";
        }

        return back()->with("status", $message);
    }
}
