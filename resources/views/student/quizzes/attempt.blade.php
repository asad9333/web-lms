@extends("layouts.app")
@section("title", $quiz->title)
@section("content")
<div class="mt-8 max-w-2xl">
    <h1 class="text-2xl font-semibold mb-1">{{ $quiz->title }}</h1>
    <p class="text-sm text-gray-500 mb-6">Closes {{ $quiz->available_until }} — Total {{ $quiz->total_marks }} marks</p>

    @if ($existing)
        <div class="bg-blue-50 border border-blue-200 text-blue-800 p-4 rounded">
            You already submitted this quiz. Score: {{ $existing->score ?? "Pending" }} / {{ $quiz->total_marks }}
        </div>
    @else
        <form method="POST" action="{{ route("student.quizzes.submit", $quiz) }}" class="bg-white p-6 rounded shadow space-y-5">
            @csrf
            @foreach ($quiz->questions as $question)
                <div class="border-b pb-4">
                    <p class="font-medium mb-2">{{ $loop->iteration }}. {{ $question->question_text }} <span class="text-gray-400 text-sm">({{ $question->marks }} marks)</span></p>

                    @if ($question->type === "mcq")
                        @foreach ($question->options ?? [] as $option)
                            @if ($option)
                                <label class="block text-sm mb-1">
                                    <input type="radio" name="answers[{{ $question->id }}]" value="{{ $option }}" required>
                                    {{ $option }}
                                </label>
                            @endif
                        @endforeach
                    @else
                        <input type="text" name="answers[{{ $question->id }}]" class="w-full border rounded px-3 py-2" required>
                    @endif
                </div>
            @endforeach
            <button type="submit" class="w-full bg-slate-800 text-white py-2 rounded hover:bg-slate-700">
                Submit Quiz
            </button>
        </form>
    @endif
</div>
@endsection
