<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Smalot\PdfParser\Parser as PdfParser;

/**
 * Shared AI text client. Sends a text prompt to Gemini first; if Gemini
 * fails for any reason (busy, rate-limited, down, bad key), automatically
 * falls back to Groq. Both are called as plain text-in/text-out, so any
 * source material (PDF etc.) must be converted to text before calling
 * generate().
 */
class AIProviderClient
{
    public function extractPdfText(string $filePath): string
    {
        $parser = new PdfParser();
        $pdf = $parser->parseFile($filePath);

        return $pdf->getText();
    }

    /**
     * Sends an image (jpg/png/webp) plus a text prompt to Gemini's vision
     * model. There is no Groq fallback here — the configured Groq model is
     * text-only, so if Gemini vision fails/unavailable this throws.
     *
     * @return string raw text response from Gemini
     */
    public function generateFromImage(string $prompt, string $imagePath, string $mimeType, int $maxTokens = 2048): string
    {
        $apiKey = config("services.gemini.key");

        if (! $apiKey) {
            throw new \RuntimeException("GEMINI_API_KEY not set");
        }

        $model = config("services.gemini.model", "gemini-3.6-flash");
        $base64 = base64_encode(file_get_contents($imagePath));

        $response = Http::timeout(180)->connectTimeout(30)->post(
            "https://generativelanguage.googleapis.com/v1beta/models/{$model}:generateContent?key={$apiKey}",
            [
                "contents" => [
                    [
                        "parts" => [
                            ["inline_data" => ["mime_type" => $mimeType, "data" => $base64]],
                            ["text" => $prompt],
                        ],
                    ],
                ],
                "generationConfig" => [
                    "maxOutputTokens" => $maxTokens,
                    "responseMimeType" => "application/json",
                ],
            ]
        );

        if (! $response->successful()) {
            throw new \RuntimeException("Gemini vision request failed: " . $response->body());
        }

        $text = $response->json("candidates.0.content.parts.0.text");

        if (! $text) {
            throw new \RuntimeException("Gemini vision returned empty response: " . $response->body());
        }

        return $text;
    }

    /**
     * @return string raw text response from whichever provider succeeded
     */
    public function generate(string $prompt, int $maxTokens = 2048): string
    {
        try {
            return $this->callGemini($prompt, $maxTokens);
        } catch (\Throwable $e) {
            Log::warning("Gemini failed, falling back to Groq: " . $e->getMessage());

            return $this->callGroq($prompt, $maxTokens);
        }
    }

    private function callGemini(string $prompt, int $maxTokens): string
    {
        $apiKey = config("services.gemini.key");

        if (! $apiKey) {
            throw new \RuntimeException("GEMINI_API_KEY not set");
        }

        $model = config("services.gemini.model", "gemini-3.6-flash");

        $response = Http::timeout(180)->connectTimeout(30)->post(
            "https://generativelanguage.googleapis.com/v1beta/models/{$model}:generateContent?key={$apiKey}",
            [
                "contents" => [
                    ["parts" => [["text" => $prompt]]],
                ],
                "generationConfig" => [
                    "maxOutputTokens" => $maxTokens,
                    "responseMimeType" => "application/json",
                ],
            ]
        );

        if (! $response->successful()) {
            throw new \RuntimeException("Gemini request failed: " . $response->body());
        }

        $text = $response->json("candidates.0.content.parts.0.text");

        if (! $text) {
            throw new \RuntimeException("Gemini returned empty response: " . $response->body());
        }

        return $text;
    }

    private function callGroq(string $prompt, int $maxTokens): string
    {
        $apiKey = config("services.groq.key");

        if (! $apiKey) {
            throw new \RuntimeException("Both Gemini and Groq failed — GROQ_API_KEY not set");
        }

        $model = config("services.groq.model", "llama-3.3-70b-versatile");

        $response = Http::withToken($apiKey)->timeout(180)->connectTimeout(30)->post(
            "https://api.groq.com/openai/v1/chat/completions",
            [
                "model" => $model,
                "messages" => [
                    [
                        "role" => "user",
                        "content" => $prompt . "\n\nRespond with ONLY valid JSON, no markdown fences, no extra text.",
                    ],
                ],
                "max_tokens" => $maxTokens,
                "response_format" => ["type" => "json_object"],
            ]
        );

        if (! $response->successful()) {
            throw new \RuntimeException("Groq request also failed: " . $response->body());
        }

        $text = $response->json("choices.0.message.content");

        if (! $text) {
            throw new \RuntimeException("Groq returned empty response: " . $response->body());
        }

        return $text;
    }
}
