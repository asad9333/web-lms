<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class AdminSeeder extends Seeder
{
    public function run(): void
    {
        User::updateOrCreate(
            ["registration_number" => "ADMIN-001"],
            [
                "name" => "System Admin",
                "email" => "admin@example.com",
                "password" => Hash::make("admin123"),
                "role" => "admin",
                "must_change_password" => true,
            ]
        );
    }
}
