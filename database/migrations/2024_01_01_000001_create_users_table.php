<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create("users", function (Blueprint $table) {
            $table->id();
            $table->string("registration_number")->unique();
            $table->string("name");
            $table->string("email")->nullable()->unique();
            $table->string("password");
            $table->enum("role", ["admin", "teacher", "student"])->default("student");
            $table->boolean("must_change_password")->default(true);
            $table->rememberToken();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists("users");
    }
};
