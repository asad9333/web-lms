<?php

namespace App\Http\Controllers\Auth;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;

class LoginController extends Controller
{
    /**
     * Step 1: just ask for the registration number.
     */
    public function showStep1()
    {
        return view("auth.login");
    }

    /**
     * Look up the registration number and decide the next step:
     * - first-ever login (no password set yet) -> straight to "set your password"
     * - returning user -> ask for their password
     */
    public function checkRegistration(Request $request)
    {
        $data = $request->validate([
            "registration_number" => ["required", "string", "exists:users,registration_number"],
        ], [
            "registration_number.exists" => "No account found with that registration number.",
        ]);

        $user = User::where("registration_number", $data["registration_number"])->first();

        $request->session()->put("login_reg_number", $user->registration_number);

        if ($user->must_change_password) {
            return redirect()->route("login.setup-password");
        }

        return redirect()->route("login.password");
    }

    /**
     * Step 2a: returning user enters their password.
     */
    public function showPasswordStep(Request $request)
    {
        $registrationNumber = $request->session()->get("login_reg_number");
        abort_unless($registrationNumber, 403);

        return view("auth.login-password", ["registrationNumber" => $registrationNumber]);
    }

    public function login(Request $request)
    {
        $registrationNumber = $request->session()->get("login_reg_number");
        abort_unless($registrationNumber, 403);

        $request->validate([
            "password" => ["required", "string"],
        ]);

        if (! Auth::attempt(["registration_number" => $registrationNumber, "password" => $request->password])) {
            return back()->withErrors(["password" => "Incorrect password."]);
        }

        $request->session()->forget("login_reg_number");
        $request->session()->regenerate();

        return $this->redirectForRole(Auth::user());
    }

    /**
     * Step 2b: first-ever login, user picks their own password (no temp
     * password involved anywhere).
     */
    public function showSetupPassword(Request $request)
    {
        $registrationNumber = $request->session()->get("login_reg_number");
        abort_unless($registrationNumber, 403);

        $user = User::where("registration_number", $registrationNumber)->first();
        abort_unless($user && $user->must_change_password, 403);

        return view("auth.setup-password", ["registrationNumber" => $registrationNumber]);
    }

    public function storeSetupPassword(Request $request)
    {
        $registrationNumber = $request->session()->get("login_reg_number");
        abort_unless($registrationNumber, 403);

        $user = User::where("registration_number", $registrationNumber)->first();
        abort_unless($user && $user->must_change_password, 403);

        $request->validate([
            "password" => ["required", "string", "min:6", "confirmed"],
        ]);

        $user->password = Hash::make($request->password);
        $user->must_change_password = false;
        $user->save();

        Auth::login($user);
        $request->session()->forget("login_reg_number");
        $request->session()->regenerate();

        return $this->redirectForRole($user);
    }

    public function logout(Request $request)
    {
        Auth::logout();
        $request->session()->invalidate();
        $request->session()->regenerateToken();

        return redirect()->route("login");
    }

    private function redirectForRole(User $user)
    {
        return match ($user->role) {
            "admin" => redirect()->route("admin.dashboard"),
            "teacher" => redirect()->route("teacher.dashboard"),
            "student" => redirect()->route("student.dashboard"),
            default => redirect("/"),
        };
    }
}
