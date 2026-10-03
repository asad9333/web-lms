<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create("assignment_submissions", function (Blueprint $table) {
            $table->id();
            $table->foreignId("assignment_id")->constrained()->cascadeOnDelete();
            $table->foreignId("student_id")->constrained("users")->cascadeOnDelete();
            $table->string("file_path");
            $table->unsignedInteger("score")->nullable();
            $table->text("feedback")->nullable();
            $table->timestamp("submitted_at");
            $table->timestamp("checked_at")->nullable();
            $table->timestamps();
            $table->unique(["assignment_id", "student_id"]);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists("assignment_submissions");
    }
};
