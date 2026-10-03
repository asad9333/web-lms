@extends("layouts.app")
@section("title", $assignment->title . " — Submissions")
@section("content")
<div class="mt-8">
    <div class="flex items-center justify-between mb-1">
        <h1 class="text-2xl font-semibold">{{ $assignment->title }} — Submissions</h1>
        @if ($assignment->submissions->whereNull("checked_at")->count())
            <form method="POST" action="{{ route("teacher.assignments.ai-check-all", [$course, $assignment]) }}">
                @csrf
                <button class="bg-slate-800 text-white text-sm px-4 py-2 rounded hover:bg-slate-700">
                    Check All with AI ({{ $assignment->submissions->whereNull("checked_at")->count() }} pending)
                </button>
            </form>
        @endif
    </div>
    <p class="text-sm text-gray-500 mb-6">Total marks: {{ $assignment->total_marks }}. Use "Check with AI" to auto-grade, or set a score manually below.</p>

    {{-- ===================== SUBMISSIONS LIST SECTION ===================== --}}
    <div class="space-y-4">
        @forelse ($assignment->submissions as $submission)
            <div class="bg-white p-5 rounded shadow">
                <div class="flex items-center justify-between mb-3">
                    <div>
                        <p class="font-medium">{{ $submission->student->name }} ({{ $submission->student->registration_number }})</p>
                        <p class="text-xs text-gray-400">Submitted {{ $submission->submitted_at }}</p>
                    </div>
                    <div class="flex items-center gap-3">
                        <a href="{{ Storage::url($submission->file_path) }}" target="_blank" class="text-slate-800 hover:underline text-sm">
                            View / Download File
                        </a>
                        <form method="POST" action="{{ route("teacher.assignments.submissions.ai-check", [$course, $assignment, $submission]) }}">
                            @csrf
                            <button class="bg-slate-100 text-slate-800 text-sm px-3 py-1.5 rounded hover:bg-slate-200">
                                {{ $submission->checked_at ? "Re-check with AI" : "Check with AI" }}
                            </button>
                        </form>
                    </div>
                </div>

                <form method="POST" action="{{ route("teacher.assignments.grade", [$course, $submission]) }}" class="grid grid-cols-4 gap-3 items-end">
                    @csrf
                    <div>
                        <label class="block text-xs text-gray-500 mb-1">Score (/ {{ $assignment->total_marks }})</label>
                        <input type="number" name="score" value="{{ $submission->score }}" min="0" max="{{ $assignment->total_marks }}" class="w-full border rounded px-2 py-1.5" required>
                    </div>
                    <div class="col-span-2">
                        <label class="block text-xs text-gray-500 mb-1">Feedback</label>
                        <input type="text" name="feedback" value="{{ $submission->feedback }}" class="w-full border rounded px-2 py-1.5">
                    </div>
                    <div>
                        <button class="bg-slate-800 text-white px-4 py-1.5 rounded hover:bg-slate-700 w-full">
                            {{ $submission->checked_at ? "Update Grade" : "Save Grade" }}
                        </button>
                    </div>
                </form>

                @if ($submission->checked_at)
                    <p class="text-xs text-gray-400 mt-2">Checked {{ $submission->checked_at }}</p>
                @else
                    <p class="text-xs text-amber-600 mt-2">Not checked yet — use "Check with AI" above or set a score manually.</p>
                @endif
            </div>
        @empty
            <p class="text-gray-500">No submissions yet.</p>
        @endforelse
    </div>
    {{-- =================== END SUBMISSIONS LIST SECTION ===================== --}}
</div>
@endsection
