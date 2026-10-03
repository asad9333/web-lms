<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create("quizzes", function (Blueprint $table) {
            $table->id();
            $table->foreignId("course_id")->constrained()->cascadeOnDelete();
            $table->string("title");
            $table->text("topics_covered")->nullable();
            $table->unsignedInteger("total_marks")->default(0);
            $table->timestamp("available_from");
            $table->timestamp("available_until");
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists("quizzes");
    }
};
