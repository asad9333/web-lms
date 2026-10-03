<?php

namespace App\Http\Controllers\Auth;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class PasswordController extends Controller
{
    public function show()
    {
        return view("auth.change-password");
    }

    public function update(Request $request)
    {
        $request->validate([
            "password" => ["required", "string", "min:6", "confirmed"],
        ]);

        $user = $request->user();
        $user->password = Hash::make($request->password);
        $user->must_change_password = false;
        $user->save();

        return match ($user->role) {
            "admin" => redirect()->route("admin.dashboard"),
            "teacher" => redirect()->route("teacher.dashboard"),
            "student" => redirect()->route("student.dashboard"),
            default => redirect("/"),
        };
    }
}
