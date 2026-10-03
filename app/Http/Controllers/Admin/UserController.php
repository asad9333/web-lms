<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class UserController extends Controller
{
    public function dashboard()
    {
        $teacherCount = User::where("role", "teacher")->count();
        $studentCount = User::where("role", "student")->count();

        return view("admin.dashboard", compact("teacherCount", "studentCount"));
    }

    public function index()
    {
        $users = User::whereIn("role", ["teacher", "student"])->latest()->paginate(20);

        return view("admin.users.index", compact("users"));
    }

    public function create()
    {
        return view("admin.users.create");
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            "registration_number" => ["required", "string", "unique:users,registration_number"],
            "name" => ["required", "string", "max:255"],
            "email" => ["nullable", "email", "unique:users,email"],
            "role" => ["required", "in:teacher,student"],
        ]);

        User::create([
            "registration_number" => $data["registration_number"],
            "name" => $data["name"],
            "email" => $data["email"] ?? null,
            "role" => $data["role"],
            "password" => Hash::make(Str::random(32)),
            "must_change_password" => true,
        ]);

        return redirect()
            ->route("admin.users.index")
            ->with("status", "User created. They can log in with registration number \"{$data["registration_number"]}\" — it will ask them to set their own password on first login.");
    }

    public function resetPassword(User $user)
    {
        $user->update([
            "password" => Hash::make(Str::random(32)),
            "must_change_password" => true,
        ]);

        return redirect()
            ->route("admin.users.index")
            ->with("status", "Password reset for \"{$user->registration_number}\" — they will be asked to set a new password on next login.");
    }

    public function destroy(User $user)
    {
        $user->delete();

        return redirect()->route("admin.users.index")->with("status", "User removed.");
    }
}
