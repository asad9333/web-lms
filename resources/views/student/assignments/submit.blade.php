@extends("layouts.app")
@section("title", $assignment->title)
@section("content")
<div class="mt-8 max-w-md">
    <h1 class="text-2xl font-semibold mb-1">{{ $assignment->title }}</h1>
    <p class="text-sm text-gray-500 mb-6">Due {{ $assignment->available_until }} — {{ $assignment->total_marks }} marks</p>

    @if ($assignment->description)
        <div class="bg-gray-50 border p-4 rounded mb-6 text-sm">{{ $assignment->description }}</div>
    @endif

    @if ($existing)
        <div class="bg-blue-50 border border-blue-200 text-blue-800 p-4 rounded">
            Submitted on {{ $existing->submitted_at }}. Score: {{ $existing->score ?? "Pending" }} / {{ $assignment->total_marks }}
            @if ($existing->feedback)
                <p class="mt-2">Feedback: {{ $existing->feedback }}</p>
            @endif
        </div>
    @else
        <form method="POST" action="{{ route("student.assignments.submit", $assignment) }}" enctype="multipart/form-data" class="bg-white p-6 rounded shadow space-y-4">
            @csrf
            <div>
                <label class="block text-sm font-medium mb-1">Upload your work (PDF / image / doc)</label>
                <input type="file" name="file" class="w-full border rounded px-3 py-2" required>
            </div>
            <button type="submit" class="w-full bg-slate-800 text-white py-2 rounded hover:bg-slate-700">
                Submit Assignment
            </button>
        </form>
    @endif
</div>
@endsection
