<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create("quiz_questions", function (Blueprint $table) {
            $table->id();
            $table->foreignId("quiz_id")->constrained()->cascadeOnDelete();
            $table->text("question_text");
            $table->enum("type", ["mcq", "short"])->default("mcq");
            $table->json("options")->nullable();
            $table->string("correct_answer")->nullable();
            $table->unsignedInteger("marks")->default(1);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists("quiz_questions");
    }
};
