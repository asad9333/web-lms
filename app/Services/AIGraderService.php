<?php

namespace App\Services;

use App\Models\QuizSubmission;
use App\Models\AssignmentSubmission;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Log;

/**
 * Central place for all auto-grading logic.
 *
 * Quiz MCQ questions are graded by exact match against correct_answer.
 * Quiz short/written questions and assignment file submissions are graded
 * by AIProviderClient, which tries Gemini first and automatically falls
 * back to Groq if Gemini is unavailable.
 *
 * Assignment submissions: PDF and DOCX are converted to text first. JPG/PNG/
 * WEBP (e.g. a photographed handwritten submission) are sent straight to
 * Gemini's vision model — there is no Groq fallback for images.
 */
class AIGraderService
{
    public function __construct(private AIProviderClient $ai) {}

    public function gradeQuizSubmission(QuizSubmission $submission): void
    {
        $quiz = $submission->quiz()->with("questions")->first();
        $answers = $submission->answers;
        $score = 0;

        foreach ($quiz->questions as $question) {
            $given = $answers[$question->id] ?? null;

            if ($given === null || trim($given) === "") {
                continue;
            }

            if ($question->type === "mcq") {
                if (mb_strtolower(trim($given)) === mb_strtolower(trim((string) $question->correct_answer))) {
                    $score += $question->marks;
                }
                continue;
            }

            // written/short answer -> AI-checked, partial credit allowed
            try {
                $score += $this->gradeShortAnswer(
                    $question->question_text,
                    (string) $question->correct_answer,
                    $given,
                    (int) $question->marks
                );
            } catch (\Throwable $e) {
                Log::error("AI short-answer grading failed, falling back to exact match: " . $e->getMessage());

                if (mb_strtolower(trim($given)) === mb_strtolower(trim((string) $question->correct_answer))) {
                    $score += $question->marks;
                }
            }
        }

        $submission->update([
            "score" => $score,
            "checked_at" => now(),
        ]);
    }

    private function gradeShortAnswer(string $questionText, string $expected, string $given, int $maxMarks): int
    {
        $prompt = <<<PROMPT
Question: {$questionText}
Expected/model answer: {$expected}
Student's answer: {$given}
Maximum marks: {$maxMarks}

Grade the student's answer against the expected answer, allowing for different
wording that means the same thing. Give partial credit where reasonable.

Respond with ONLY a JSON object, no other text, no markdown code fences:
{"marks": <integer 0 to {$maxMarks}>}
PROMPT;

        $text = $this->ai->generate($prompt, 256);
        $decoded = $this->extractJsonObject($text);

        return min((int) ($decoded["marks"] ?? 0), $maxMarks);
    }

    public function gradeAssignmentSubmission(AssignmentSubmission $submission): void
    {
        $assignment = $submission->assignment;

        $filePath = Storage::disk("public")->path($submission->file_path);

        if (! file_exists($filePath)) {
            Log::warning("Skipped AI grading: submission file not found at {$filePath}.");
            return;
        }

        $extension = strtolower(pathinfo($filePath, PATHINFO_EXTENSION));
        $imageMimes = ["jpg" => "image/jpeg", "jpeg" => "image/jpeg", "png" => "image/png", "webp" => "image/webp"];

        if ($extension === "pdf") {
            try {
                $submissionText = $this->ai->extractPdfText($filePath);
            } catch (\Throwable $e) {
                Log::error("Could not extract text from submission PDF: " . $e->getMessage());
                return;
            }
        } elseif ($extension === "docx") {
            $submissionText = $this->extractDocxText($filePath);

            if ($submissionText === null) {
                Log::warning("Skipped AI grading: could not extract text from docx file ({$filePath}).");
                return;
            }
        } elseif (isset($imageMimes[$extension])) {
            $prompt = <<<PROMPT
You are grading a student assignment submission for a course.

Assignment title: {$assignment->title}
Assignment instructions: {$assignment->description}
Topics this assignment covers: {$assignment->topics_covered}
Total marks available: {$assignment->total_marks}

Look at the attached image, which is a photo/scan of the student's submitted
work (it may be handwritten), and grade it against the instructions and
topics above.

Respond with ONLY a JSON object, no other text, no markdown code fences, in
exactly this shape:
{"score": <integer 0 to {$assignment->total_marks}>, "feedback": "<2-4 sentence feedback for the student>"}
PROMPT;

            try {
                $text = $this->ai->generateFromImage($prompt, $filePath, $imageMimes[$extension]);
            } catch (\Throwable $e) {
                Log::error("AI image grading failed: " . $e->getMessage());
                return;
            }

            $result = $this->extractJsonObject($text);

            if (! $result) {
                Log::error("AI grading: could not parse JSON from image response: " . $text);
                return;
            }

            $submission->update([
                "score" => min((int) ($result["score"] ?? 0), $assignment->total_marks),
                "feedback" => $result["feedback"] ?? null,
                "checked_at" => now(),
            ]);

            return;
        } else {
            Log::warning("Skipped AI grading: unsupported file type '{$extension}' for text-based grading (file: {$filePath}).");
            return;
        }

        $submissionText = mb_substr($submissionText, 0, 20000);

        $prompt = <<<PROMPT
You are grading a student assignment submission for a course.

Assignment title: {$assignment->title}
Assignment instructions: {$assignment->description}
Topics this assignment covers: {$assignment->topics_covered}
Total marks available: {$assignment->total_marks}

--- SUBMITTED WORK START ---
{$submissionText}
--- SUBMITTED WORK END ---

Grade the submitted work against the instructions and topics above.

Respond with ONLY a JSON object, no other text, no markdown code fences, in
exactly this shape:
{"score": <integer 0 to {$assignment->total_marks}>, "feedback": "<2-4 sentence feedback for the student>"}
PROMPT;

        try {
            $text = $this->ai->generate($prompt, 1024);
        } catch (\Throwable $e) {
            Log::error("AI grading request failed on both providers: " . $e->getMessage());
            return;
        }

        $result = $this->extractJsonObject($text);

        if (! $result) {
            Log::error("AI grading: could not parse JSON from response: " . $text);
            return;
        }

        $submission->update([
            "score" => min((int) ($result["score"] ?? 0), $assignment->total_marks),
            "feedback" => $result["feedback"] ?? null,
            "checked_at" => now(),
        ]);
    }

    private function extractDocxText(string $filePath): ?string
    {
        $zip = new \ZipArchive();

        if ($zip->open($filePath) !== true) {
            return null;
        }

        $xml = $zip->getFromName("word/document.xml");
        $zip->close();

        if ($xml === false) {
            return null;
        }

        $xml = preg_replace("/<\/w:p>/", "\n", $xml);
        $xml = preg_replace("/<[^>]+>/", " ", $xml);
        $text = trim(html_entity_decode(preg_replace("/\s+/", " ", $xml)));

        return $text !== "" ? mb_substr($text, 0, 20000) : null;
    }

    private function extractJsonObject(?string $text): ?array
    {
        if (! $text) {
            return null;
        }

        $text = trim(preg_replace('/^```json|```$/m', '', $text));

        $decoded = json_decode($text, true);

        if (is_array($decoded)) {
            return $decoded;
        }

        if (preg_match("/\{.*\}/s", $text, $matches)) {
            $decoded = json_decode($matches[0], true);
            return is_array($decoded) ? $decoded : null;
        }

        return null;
    }
}
