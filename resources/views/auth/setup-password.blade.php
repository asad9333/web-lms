@extends("layouts.app")
@section("title", "Set Your Password")
@section("content")
<div class="max-w-sm mx-auto mt-16 bg-white p-6 rounded shadow">
    <h1 class="text-xl font-semibold mb-1">Set Your Password</h1>
    <p class="text-sm text-gray-500 mb-4">{{ $registrationNumber }} — this is your first login. Choose a password to continue.</p>
    <form method="POST" action="{{ route("login.setup-password.submit") }}" class="space-y-4">
        @csrf
        <div>
            <label class="block text-sm font-medium mb-1">New Password</label>
            <input type="password" name="password" class="w-full border rounded px-3 py-2" required minlength="6" autofocus>
        </div>
        <div>
            <label class="block text-sm font-medium mb-1">Confirm Password</label>
            <input type="password" name="password_confirmation" class="w-full border rounded px-3 py-2" required minlength="6">
        </div>
        <button type="submit" class="w-full bg-slate-800 text-white py-2 rounded hover:bg-slate-700">
            Set Password & Login
        </button>
    </form>
</div>
@endsection
