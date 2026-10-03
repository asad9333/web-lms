@extends("layouts.app")
@section("title", "Admin Dashboard")
@section("content")
<div class="mt-8">
    <h1 class="text-2xl font-semibold mb-6">Admin Dashboard</h1>

    {{-- ===================== STATS SECTION ===================== --}}
    <div class="grid grid-cols-2 gap-4 mb-8">
        <div class="bg-white p-5 rounded shadow">
            <p class="text-sm text-gray-500">Teachers</p>
            <p class="text-3xl font-bold">{{ $teacherCount }}</p>
        </div>
        <div class="bg-white p-5 rounded shadow">
            <p class="text-sm text-gray-500">Students</p>
            <p class="text-3xl font-bold">{{ $studentCount }}</p>
        </div>
    </div>
    {{-- =================== END STATS SECTION ===================== --}}

    <a href="{{ route("admin.users.index") }}" class="bg-slate-800 text-white px-4 py-2 rounded hover:bg-slate-700">
        Manage Users
    </a>
</div>
@endsection
