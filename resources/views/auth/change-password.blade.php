@extends("layouts.app")
@section("title", "Change Password")
@section("content")
<div class="max-w-sm mx-auto mt-16 bg-white p-6 rounded shadow">
    <h1 class="text-xl font-semibold mb-2">Set a New Password</h1>
    <p class="text-sm text-gray-500 mb-4">This is your first login (or an admin-assigned password). Please set your own password to continue.</p>
    <form method="POST" action="{{ route("password.update") }}" class="space-y-4">
        @csrf
        <div>
            <label class="block text-sm font-medium mb-1">New Password</label>
            <input type="password" name="password" class="w-full border rounded px-3 py-2" required minlength="6">
        </div>
        <div>
            <label class="block text-sm font-medium mb-1">Confirm Password</label>
            <input type="password" name="password_confirmation" class="w-full border rounded px-3 py-2" required minlength="6">
        </div>
        <button type="submit" class="w-full bg-slate-800 text-white py-2 rounded hover:bg-slate-700">
            Save Password
        </button>
    </form>
</div>
@endsection
