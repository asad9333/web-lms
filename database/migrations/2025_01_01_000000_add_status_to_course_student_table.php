<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table("course_student", function (Blueprint $table) {
            // Existing rows (created by the old direct-enroll flow) default to
            // "approved" so nothing already enrolled gets hidden. New requests
            // created by students default to "pending" (set explicitly in code).
            $table->string("status")->default("approved")->after("student_id");
        });
    }

    public function down(): void
    {
        Schema::table("course_student", function (Blueprint $table) {
            $table->dropColumn("status");
        });
    }
};
