@extends("layouts.app")
@section("title", "Teacher Dashboard")
@section("content")
<div class="mt-8">
    <div class="flex items-center justify-between mb-6">
        <h1 class="text-2xl font-semibold">My Courses</h1>
        <a href="{{ route("teacher.courses.create") }}" class="bg-slate-800 text-white px-4 py-2 rounded hover:bg-slate-700">
            + New Course
        </a>
    </div>

    {{-- ===================== COURSE LIST SECTION ===================== --}}
    <div class="grid gap-4">
        @forelse ($courses as $course)
            <a href="{{ route("teacher.courses.show", $course) }}" class="bg-white p-5 rounded shadow hover:shadow-md block">
                <h2 class="font-semibold text-lg">{{ $course->title }}</h2>
                <p class="text-sm text-gray-500 mt-1">
                    {{ $course->students_count }} students ·
                    {{ $course->materials_count }} materials ·
                    {{ $course->quizzes_count }} quizzes ·
                    {{ $course->assignments_count }} assignments
                </p>
            </a>
        @empty
            <p class="text-gray-500">No courses yet.</p>
        @endforelse
    </div>
    {{-- =================== END COURSE LIST SECTION ===================== --}}
</div>
@endsection
