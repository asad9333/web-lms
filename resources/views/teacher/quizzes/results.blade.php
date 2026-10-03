@extends("layouts.app")
@section("title", "Quiz Results")
@section("content")
<div class="mt-8">
    <div class="flex items-center justify-between mb-6">
        <h1 class="text-2xl font-semibold">{{ $quiz->title }} — Results</h1>
        @if ($quiz->submissions->whereNull("checked_at")->count())
            <form method="POST" action="{{ route("teacher.quizzes.ai-check-all", [$course, $quiz]) }}">
                @csrf
                <button class="bg-slate-800 text-white text-sm px-4 py-2 rounded hover:bg-slate-700">
                    Check All with AI ({{ $quiz->submissions->whereNull("checked_at")->count() }} pending)
                </button>
            </form>
        @endif
    </div>

    {{-- ===================== RESULTS TABLE SECTION ===================== --}}
    <div class="bg-white rounded shadow overflow-x-auto">
        <table class="w-full text-sm">
            <thead class="bg-gray-50 text-left">
                <tr>
                    <th class="px-4 py-3">Student</th>
                    <th class="px-4 py-3">Score</th>
                    <th class="px-4 py-3">Submitted At</th>
                    <th class="px-4 py-3">Status</th>
                    <th class="px-4 py-3"></th>
                </tr>
            </thead>
            <tbody>
                @forelse ($quiz->submissions as $submission)
                    <tr class="border-t">
                        <td class="px-4 py-3">{{ $submission->student->name }}</td>
                        <td class="px-4 py-3">{{ $submission->score ?? "Pending" }} / {{ $quiz->total_marks }}</td>
                        <td class="px-4 py-3">{{ $submission->submitted_at }}</td>
                        <td class="px-4 py-3">
                            @if ($submission->checked_at)
                                <span class="text-green-700 bg-green-50 text-xs px-2 py-1 rounded">Checked</span>
                            @else
                                <span class="text-amber-700 bg-amber-50 text-xs px-2 py-1 rounded">Pending</span>
                            @endif
                        </td>
                        <td class="px-4 py-3">
                            <form method="POST" action="{{ route("teacher.quizzes.submissions.ai-check", [$course, $quiz, $submission]) }}">
                                @csrf
                                <button class="text-slate-800 hover:underline text-xs">
                                    {{ $submission->checked_at ? "Re-check with AI" : "Check with AI" }}
                                </button>
                            </form>
                        </td>
                    </tr>
                @empty
                    <tr><td class="px-4 py-3 text-gray-500" colspan="5">No submissions yet.</td></tr>
                @endforelse
            </tbody>
        </table>
    </div>
    {{-- =================== END RESULTS TABLE SECTION ===================== --}}
</div>
@endsection
