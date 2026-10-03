@extends("layouts.app")
@section("title", $course->title)
@section("content")
<div class="mt-8 space-y-6">
    <div>
        <a href="{{ route("student.dashboard") }}" class="text-sm text-slate-500 hover:underline">← Back to dashboard</a>
        <h1 class="text-2xl font-semibold mt-1">{{ $course->title }}</h1>
    </div>

    <div class="bg-white p-5 rounded shadow">
        <h2 class="font-medium text-sm text-gray-500">Open Quizzes</h2>
        <ul class="text-sm divide-y">
            @forelse ($course->quizzes->filter(fn ($q) => $q->isOpen()) as $quiz)
                <li class="py-2 flex justify-between">
                    <span>{{ $quiz->title }} (closes {{ $quiz->available_until }})</span>
                    <a href="{{ route("student.quizzes.show", $quiz) }}" class="text-slate-800 hover:underline">Attempt</a>
                </li>
            @empty
                <li class="py-2 text-gray-400">None open right now.</li>
            @endforelse
        </ul>

        <h2 class="font-medium text-sm text-gray-500 mt-5">Open Assignments</h2>
        <ul class="text-sm divide-y">
            @forelse ($course->assignments->filter(fn ($a) => $a->isOpen()) as $assignment)
                <li class="py-2 flex justify-between">
                    <span>{{ $assignment->title }} (due {{ $assignment->available_until }})</span>
                    <a href="{{ route("student.assignments.show", $assignment) }}" class="text-slate-800 hover:underline">Submit</a>
                </li>
            @empty
                <li class="py-2 text-gray-400">None open right now.</li>
            @endforelse
        </ul>
    </div>

    @if ($gradedQuizzes->count() || $gradedAssignments->count())
        <div class="bg-white p-5 rounded shadow">
            <h2 class="font-semibold text-lg mb-2">Your Results</h2>

            @if ($gradedQuizzes->count())
                <h3 class="text-sm font-medium text-gray-500 mt-3">Quizzes</h3>
                <ul class="text-sm divide-y">
                    @foreach ($gradedQuizzes as $submission)
                        <li class="py-2 flex justify-between">
                            <span>{{ $submission->quiz->title }}</span>
                            <span class="font-medium">{{ $submission->score }} / {{ $submission->quiz->total_marks }}</span>
                        </li>
                    @endforeach
                </ul>
            @endif

            @if ($gradedAssignments->count())
                <h3 class="text-sm font-medium text-gray-500 mt-3">Assignments</h3>
                <ul class="text-sm divide-y">
                    @foreach ($gradedAssignments as $submission)
                        <li class="py-2">
                            <div class="flex justify-between">
                                <span>{{ $submission->assignment->title }}</span>
                                <span class="font-medium">{{ $submission->score }} / {{ $submission->assignment->total_marks }}</span>
                            </div>
                            @if ($submission->feedback)
                                <p class="text-gray-500 mt-1">{{ $submission->feedback }}</p>
                            @endif
                        </li>
                    @endforeach
                </ul>
            @endif
        </div>
    @endif
</div>
@endsection
