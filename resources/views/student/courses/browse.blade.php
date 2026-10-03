@extends("layouts.app")
@section("title", "Browse Courses")
@section("content")
<div class="mt-8 space-y-6">
    <div>
        <a href="{{ route("student.dashboard") }}" class="text-sm text-slate-500 hover:underline">← Back to dashboard</a>
        <h1 class="text-2xl font-semibold mt-1">Browse Courses</h1>
    </div>

    @if ($pendingCourses->count())
        <div class="bg-amber-50 border border-amber-200 rounded p-4">
            <p class="text-sm font-medium text-amber-800 mb-2">Awaiting teacher approval:</p>
            <ul class="text-sm text-amber-700 space-y-1">
                @foreach ($pendingCourses as $course)
                    <li>{{ $course->title }} ({{ $course->teacher->name }})</li>
                @endforeach
            </ul>
        </div>
    @endif

    <div class="grid sm:grid-cols-2 lg:grid-cols-3 gap-4">
        @forelse ($availableCourses as $course)
            <div class="bg-white p-5 rounded shadow flex flex-col justify-between">
                <div>
                    <h2 class="font-semibold text-lg">{{ $course->title }}</h2>
                    <p class="text-sm text-gray-500 mt-1">{{ $course->description ?: "No description provided." }}</p>
                    <p class="text-xs text-gray-400 mt-3">Taught by {{ $course->teacher->name }}</p>
                </div>
                <form method="POST" action="{{ route("student.courses.request-enrollment", $course) }}" class="mt-4">
                    @csrf
                    <button class="w-full bg-slate-800 text-white text-sm py-1.5 rounded hover:bg-slate-700">
                        Request to Join
                    </button>
                </form>
            </div>
        @empty
            <div class="col-span-full bg-white p-8 rounded shadow text-center text-gray-400">
                No more courses available to join right now.
            </div>
        @endforelse
    </div>
</div>
@endsection
