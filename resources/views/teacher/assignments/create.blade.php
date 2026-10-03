@extends("layouts.app")
@section("title", "Create Assignment")
@section("content")
<div class="mt-8 max-w-md"
     x-data="{
        title: '',
        description: '',
        totalMarks: '',
        aiLoading: false,
        aiError: '',
        async generateWithAi(materialId, range, totalMarks) {
            if (! materialId) { this.aiError = 'Pick a material first.'; return; }
            if (! range) { this.aiError = 'Tell it which part of the material to cover.'; return; }
            if (! totalMarks) { this.aiError = 'Enter total marks.'; return; }
            this.aiLoading = true;
            this.aiError = '';
            try {
                const res = await fetch('{{ route("teacher.assignments.generate-draft", $course) }}', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'X-CSRF-TOKEN': document.querySelector('meta[name=csrf-token]').content,
                    },
                    body: JSON.stringify({material_id: materialId, range: range, total_marks: totalMarks}),
                });
                const data = await res.json();
                if (! res.ok) { this.aiError = data.error || 'Could not generate assignment.'; return; }
                this.title = data.title || '';
                this.description = data.description || '';
                this.totalMarks = data.total_marks || totalMarks;
            } catch (e) {
                this.aiError = 'Request failed.';
            } finally {
                this.aiLoading = false;
            }
        }
     }">
    <h1 class="text-2xl font-semibold mb-6">Create Assignment — {{ $course->title }}</h1>

    {{-- ===================== AI DRAFT SECTION ===================== --}}
    <div class="bg-white border rounded p-4 mb-6 space-y-3" x-data="{ materialId: '', range: '', draftMarks: 20 }">
        <h2 class="font-medium text-sm">Draft assignment with AI (optional)</h2>
        <div class="grid grid-cols-2 gap-2">
            <select x-model="materialId" class="border rounded px-2 py-1.5 text-sm">
                <option value="">Select uploaded material...</option>
                @foreach ($materials as $material)
                    <option value="{{ $material->id }}">{{ $material->title }} ({{ $material->type }})</option>
                @endforeach
            </select>
            <input type="text" x-model="range" class="border rounded px-2 py-1.5 text-sm" placeholder="Which part? e.g. Chapter 1-2 / Page 1-20">
        </div>
        <input type="number" x-model="draftMarks" min="1" class="border rounded px-2 py-1.5 text-sm w-full" placeholder="Total marks (approx)">
        <button type="button" @click="generateWithAi(materialId, range, draftMarks)" :disabled="aiLoading"
                class="text-sm bg-slate-800 text-white px-3 py-1.5 rounded hover:bg-slate-700 disabled:opacity-50">
            <span x-show="!aiLoading">Generate Draft from Material</span>
            <span x-show="aiLoading">Generating...</span>
        </button>
        <p class="text-xs text-red-600" x-text="aiError" x-show="aiError"></p>
        <p class="text-xs text-gray-400">This fills the fields below — review and edit before saving.</p>
    </div>
    {{-- =================== END AI DRAFT SECTION ===================== --}}

    <form method="POST" action="{{ route("teacher.assignments.store", $course) }}" class="bg-white p-6 rounded shadow space-y-4">
        @csrf
        <div>
            <label class="block text-sm font-medium mb-1">Title</label>
            <input type="text" name="title" x-model="title" class="w-full border rounded px-3 py-2" required>
        </div>
        <div>
            <label class="block text-sm font-medium mb-1">Description / Instructions</label>
            <textarea name="description" rows="4" x-model="description" class="w-full border rounded px-3 py-2"></textarea>
        </div>
        <div>
            <label class="block text-sm font-medium mb-1">Total Marks</label>
            <input type="number" name="total_marks" x-model="totalMarks" min="1" class="w-full border rounded px-3 py-2" required>
        </div>
        <div>
            <label class="block text-sm font-medium mb-1">Available From</label>
            <input type="datetime-local" name="available_from" class="w-full border rounded px-3 py-2" required>
        </div>
        <div>
            <label class="block text-sm font-medium mb-1">Available Until</label>
            <input type="datetime-local" name="available_until" class="w-full border rounded px-3 py-2" required>
        </div>
        <button type="submit" class="w-full bg-slate-800 text-white py-2 rounded hover:bg-slate-700">
            Create & Notify Students
        </button>
    </form>
</div>
@endsection
