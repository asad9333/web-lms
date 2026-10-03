<?php

namespace App\Services;

use App\Models\Course;
use App\Models\CourseMaterial;
use Illuminate\Support\Facades\Storage;

/**
 * Drafts an assignment (title + description/instructions + suggested total
 * marks) from an uploaded material file, scoped to covered topics. Teacher
 * reviews/edits before saving.
 *
 * Uses AIProviderClient, which tries Gemini first and automatically falls
 * back to Groq if Gemini is unavailable.
 */
class AIAssignmentGeneratorService
{
    public function __construct(private AIProviderClient $ai) {}

    /**
     * @return array{title: string, description: string, total_marks: int, topics_covered: string}
     */
    public function draftAssignment(Course $course, CourseMaterial $material, string $range, int $totalMarks = 20): array
    {
        $coveredTopics = $course->syllabus()->where("is_covered", true)->pluck("topic")->implode(", ");

        $filePath = Storage::disk("public")->path($material->file_path);

        if (! file_exists($filePath)) {
            throw new \RuntimeException("Material file not found on disk.");
        }

        $materialText = $this->ai->extractPdfText($filePath);
        $materialText = mb_substr($materialText, 0, 20000);

        $prompt = <<<PROMPT
You are drafting a course assignment for "{$course->title}".

Only cover these topics (already taught): {$coveredTopics}

Restrict the assignment strictly to this part of the material below: {$range}

--- MATERIAL START ---
{$materialText}
--- MATERIAL END ---

The assignment should be worth around {$totalMarks} total marks (you may
adjust slightly if it makes more sense pedagogically).

Write:
- A short, clear title for the assignment
- Full description/instructions for the student (what to do, what to submit, how it will be evaluated)
- The topics it covers (comma separated)
- The total marks

Respond with ONLY a JSON object, no other text, no markdown code fences, in exactly this shape:
{"title": "...", "description": "...", "topics_covered": "...", "total_marks": 20}
PROMPT;

        $text = $this->ai->generate($prompt, 3072);

        $result = $this->extractJsonObject($text);

        if (! $result) {
            \Illuminate\Support\Facades\Log::error("Could not parse assignment draft. Raw AI response: " . $text);
            throw new \RuntimeException("Could not parse assignment draft from AI response.");
        }

        return $result;
    }

    private function extractJsonObject(?string $text): ?array
    {
        if (! $text) {
            return null;
        }

        $text = trim($text);
        $text = preg_replace('/^```(json)?/m', '', $text);
        $text = preg_replace('/```$/m', '', $text);
        $text = trim($text);

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
