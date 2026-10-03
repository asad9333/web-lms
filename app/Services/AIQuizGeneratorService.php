<?php

namespace App\Services;

use App\Models\Course;
use App\Models\CourseMaterial;
use Illuminate\Support\Facades\Storage;

/**
 * Drafts quiz questions from an uploaded material file (pdf), scoped
 * to the topics the teacher has already marked as covered. The teacher still
 * reviews and edits the draft before it is saved as a real quiz.
 *
 * Uses AIProviderClient, which tries Gemini first and automatically falls
 * back to Groq if Gemini is unavailable.
 */
class AIQuizGeneratorService
{
    public function __construct(private AIProviderClient $ai) {}

    /**
     * @return array<int, array{question_text: string, type: string, options: array<int, string>, correct_answer: string, marks: int}>
     */
    public function draftQuestions(Course $course, CourseMaterial $material, string $range, int $totalMarks, string $mix = "mixed"): array
    {
        $coveredTopics = $course->syllabus()->where("is_covered", true)->pluck("topic")->implode(", ");

        $filePath = Storage::disk("public")->path($material->file_path);

        if (! file_exists($filePath)) {
            throw new \RuntimeException("Material file not found on disk.");
        }

        $materialText = $this->ai->extractPdfText($filePath);
        $materialText = mb_substr($materialText, 0, 20000); // keep prompt within a reasonable size

        $mixInstruction = match ($mix) {
            "mcq_only" => "Every question must be type \"mcq\" with exactly 4 options.",
            "written_only" => "Every question must be type \"short\" (written answer), no MCQs.",
            default => "Use a mix of MCQ (4 options) and short-answer (written) questions.",
        };

        $prompt = <<<PROMPT
You are drafting a quiz for the course "{$course->title}".

Only cover these topics (already taught): {$coveredTopics}

Restrict the questions strictly to this part of the material below: {$range}

--- MATERIAL START ---
{$materialText}
--- MATERIAL END ---

The quiz must add up to exactly {$totalMarks} total marks. Decide how many
questions are needed and how many marks each one is worth so the marks sum
to {$totalMarks} — do not just write one question per mark.

{$mixInstruction}

Respond with ONLY a JSON object, no other text, no markdown code fences, in exactly this shape:
{"questions": [
  {"question_text": "...", "type": "mcq", "options": ["A", "B", "C", "D"], "correct_answer": "A", "marks": 2},
  {"question_text": "...", "type": "short", "options": [], "correct_answer": "expected answer", "marks": 2}
]}
PROMPT;

        $text = $this->ai->generate($prompt, 4096);

        $questions = $this->extractQuestions($text);

        if (! $questions) {
            \Illuminate\Support\Facades\Log::error("Could not parse quiz questions. Raw AI response: " . $text);
            throw new \RuntimeException("Could not parse quiz questions from AI response.");
        }

        return $questions;
    }

    private function extractQuestions(?string $text): ?array
    {
        if (! $text) {
            return null;
        }

        $text = trim($text);
        $text = preg_replace('/^```(json)?/m', '', $text);
        $text = preg_replace('/```$/m', '', $text);
        $text = trim($text);

        $decoded = json_decode($text, true);

        if (is_array($decoded) && isset($decoded["questions"]) && is_array($decoded["questions"])) {
            return $decoded["questions"];
        }

        // fallback: maybe the model returned a bare array
        if (preg_match("/\[.*\]/s", $text, $matches)) {
            $arr = json_decode($matches[0], true);
            return is_array($arr) ? $arr : null;
        }

        return null;
    }
}
