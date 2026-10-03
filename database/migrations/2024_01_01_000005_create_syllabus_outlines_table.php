<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create("syllabus_outlines", function (Blueprint $table) {
            $table->id();
            $table->foreignId("course_id")->constrained()->cascadeOnDelete();
            $table->unsignedInteger("week_number");
            $table->string("topic");
            $table->enum("phase", ["before_mid", "before_final"])->default("before_mid");
            $table->boolean("is_covered")->default(false);
            $table->timestamp("covered_at")->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists("syllabus_outlines");
    }
};
