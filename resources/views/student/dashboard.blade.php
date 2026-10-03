@extends("layouts.app")
@section("title", "Student Dashboard")
@section("content")
<div class="mt-8 grid grid-cols-3 gap-6">

    {{-- ===================== COURSES SECTION ===================== --}}
    <div class="col-span-2 space-y-6">
        <div class="flex items-center justify-between">
            <h1 class="text-2xl font-semibold">My Courses</h1>
            <a href="{{ route("student.courses.browse") }}" class="bg-slate-800 text-white text-sm px-3 py-1.5 rounded hover:bg-slate-700 flex items-center gap-1.5">
                Browse Courses
                @if ($pendingCoursesCount)
                    <span class="bg-amber-500 text-white text-xs rounded-full px-1.5 py-0.5">{{ $pendingCoursesCount }} pending</span>
                @endif
            </a>
        </div>

        <div class="grid sm:grid-cols-2 gap-4">
            @forelse ($courses as $course)
                <a href="{{ route("student.courses.show", $course) }}" class="bg-white p-5 rounded shadow hover:shadow-md transition block">
                    <h2 class="font-semibold text-lg">{{ $course->title }}</h2>
                    <p class="text-sm text-gray-500 mt-1">{{ $course->description ?: "View quizzes, assignments & results →" }}</p>
                </a>
            @empty
                <div class="col-span-full bg-white p-8 rounded shadow text-center">
                    <p class="text-gray-500">You are not enrolled in any course yet.</p>
                    <a href="{{ route("student.courses.browse") }}" class="inline-block mt-3 text-slate-800 font-medium hover:underline">Browse available courses →</a>
                </div>
            @endforelse
        </div>
    </div>
    {{-- =================== END COURSES SECTION ===================== --}}

    {{-- ===================== NOTIFICATIONS SECTION ===================== --}}
    <div class="col-span-1">
        <h2 class="text-lg font-semibold mb-3">Notifications</h2>
        <div class="bg-white rounded shadow divide-y">
            @forelse ($notifications as $note)
                <div class="p-3 text-sm">
                    <p class="font-medium">{{ $note->title }}</p>
                    <p class="text-gray-500">{{ $note->message }}</p>
                </div>
            @empty
                <p class="p-3 text-sm text-gray-400">No notifications yet.</p>
            @endforelse
        </div>
    </div>
    {{-- =================== END NOTIFICATIONS SECTION ===================== --}}

</div>
@endsection
