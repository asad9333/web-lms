@extends("layouts.app")
@section("title", "Add User")
@section("content")
<div class="mt-8 max-w-md">
    <h1 class="text-2xl font-semibold mb-6">Add Teacher / Student</h1>
    <form method="POST" action="{{ route("admin.users.store") }}" class="bg-white p-6 rounded shadow space-y-4">
        @csrf
        <div>
            <label class="block text-sm font-medium mb-1">Registration Number</label>
            <input type="text" name="registration_number" value="{{ old("registration_number") }}"
                   class="w-full border rounded px-3 py-2" required>
        </div>
        <div>
            <label class="block text-sm font-medium mb-1">Full Name</label>
            <input type="text" name="name" value="{{ old("name") }}" class="w-full border rounded px-3 py-2" required>
        </div>
        <div>
            <label class="block text-sm font-medium mb-1">Email (optional)</label>
            <input type="email" name="email" value="{{ old("email") }}" class="w-full border rounded px-3 py-2">
        </div>
        <div>
            <label class="block text-sm font-medium mb-1">Role</label>
            <select name="role" class="w-full border rounded px-3 py-2" required>
                <option value="teacher">Teacher</option>
                <option value="student">Student</option>
            </select>
        </div>
        <button type="submit" class="w-full bg-slate-800 text-white py-2 rounded hover:bg-slate-700">
            Create User (auto-generates password)
        </button>
    </form>
</div>
@endsection
