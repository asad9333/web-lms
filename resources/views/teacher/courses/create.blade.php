@extends("layouts.app")
@section("title", "New Course")
@section("content")
<div class="mt-8 max-w-md">
    <h1 class="text-2xl font-semibold mb-6">New Course</h1>
    <form method="POST" action="{{ route("teacher.courses.store") }}" class="bg-white p-6 rounded shadow space-y-4">
        @csrf
        <div>
            <label class="block text-sm font-medium mb-1">Title</label>
            <input type="text" name="title" value="{{ old("title") }}" class="w-full border rounded px-3 py-2" required>
        </div>
        <div>
            <label class="block text-sm font-medium mb-1">Description</label>
            <textarea name="description" rows="4" class="w-full border rounded px-3 py-2">{{ old("description") }}</textarea>
        </div>
        <button type="submit" class="w-full bg-slate-800 text-white py-2 rounded hover:bg-slate-700">Create</button>
    </form>
</div>
@endsection
