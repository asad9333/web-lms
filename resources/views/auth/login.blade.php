@extends("layouts.app")
@section("title", "Login")
@section("content")
<div class="max-w-sm mx-auto mt-16 bg-white p-6 rounded shadow">
    <h1 class="text-xl font-semibold mb-4">Login</h1>
    <form method="POST" action="{{ route("login.continue") }}" class="space-y-4">
        @csrf
        <div>
            <label class="block text-sm font-medium mb-1">Registration Number</label>
            <input type="text" name="registration_number" value="{{ old("registration_number") }}"
                   class="w-full border rounded px-3 py-2" required autofocus>
        </div>
        <button type="submit" class="w-full bg-slate-800 text-white py-2 rounded hover:bg-slate-700">
            Continue
        </button>
    </form>
</div>
@endsection
