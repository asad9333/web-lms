@extends("layouts.app")
@section("title", "Login")
@section("content")
<div class="max-w-sm mx-auto mt-16 bg-white p-6 rounded shadow">
    <h1 class="text-xl font-semibold mb-1">Login</h1>
    <p class="text-sm text-gray-500 mb-4">{{ $registrationNumber }}</p>
    <form method="POST" action="{{ route("login.password.submit") }}" class="space-y-4">
        @csrf
        <div>
            <label class="block text-sm font-medium mb-1">Password</label>
            <input type="password" name="password" class="w-full border rounded px-3 py-2" required autofocus>
        </div>
        <button type="submit" class="w-full bg-slate-800 text-white py-2 rounded hover:bg-slate-700">
            Login
        </button>
    </form>
    <a href="{{ route("login") }}" class="block text-center text-sm text-gray-500 mt-3 hover:underline">
        Use a different registration number
    </a>
</div>
@endsection
