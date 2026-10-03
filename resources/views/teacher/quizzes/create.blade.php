@extends("layouts.app")
@section("title", "Generate Quiz")
@section("content")
<div class="mt-8 max-w-2xl"
     x-data="{
        questions: [{question_text: '', type: 'mcq', options: ['', '', '', ''], correct_answer: '', marks: 1}],
        aiLoading: false,
        aiError: '',
        async generateWithAi(materialId, range, totalMarks, mix) {
            if (! materialId) { this.aiError = 'Pick a material first.'; return; }
            if (! range) { this.aiError = 'Tell it which part of the material to cover.'; return; }
            if (! totalMarks) { this.aiError = 'Enter total marks.'; return; }
            this.aiLoading = true;
            this.aiError = '';
            try {
                const res = await fetch('{{ route("teacher.quizzes.generate-draft", $course) }}', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'X-CSRF-TOKEN': document.querySelector('meta[name=csrf-token]').content,
                    },
                    body: JSON.stringify({material_id: materialId, range: range, total_marks: totalMarks, mix: mix}),
                });
                const data = await res.json();
                if (! res.ok) { this.aiError = data.error || 'Could not generate questions.'; return; }
                this.questions = data.questions.map(q => ({
                    question_text: q.question_text || '',
                    type: q.type || 'mcq',
                    options: (q.options && q.options.length ? q.options : ['', '', '', '']),
                    correct_answer: q.correct_answer || '',
                    marks: q.marks || 1,
                }));
            } catch (e) {
                this.aiError = 'Request failed.';
            } finally {
                this.aiLoading = false;
            }
        }
     }">
    <h1 class="text-2xl font-semibold mb-2">Generate Quiz — {{ $course->title }}</h1>

    {{-- ===================== COVERED TOPICS SECTION ===================== --}}
    <div class="bg-blue-50 border border-blue-200 text-blue-800 text-sm p-3 rounded mb-6">
        Covered so far: {{ $coveredTopics->pluck("topic")->implode(", ") ?: "No topics marked covered yet." }}
    </div>
    {{-- =================== END COVERED TOPICS SECTION ===================== --}}

    {{-- ===================== AI DRAFT SECTION ===================== --}}
    <div class="bg-white border rounded p-4 mb-6 space-y-3" x-data="{ materialId: '', range: '', totalMarks: 10, mix: 'mixed' }">
        <h2 class="font-medium text-sm">Draft questions with AI (optional)</h2>
        <div class="grid grid-cols-2 gap-2">
            <select x-model="materialId" class="border rounded px-2 py-1.5 text-sm">
                <option value="">Select uploaded material...</option>
                @foreach ($materials as $material)
                    <option value="{{ $material->id }}">{{ $material->title }} ({{ $material->type }})</option>
                @endforeach
            </select>
            <input type="text" x-model="range" class="border rounded px-2 py-1.5 text-sm" placeholder="Which part? e.g. Chapter 1-2 / Page 1-20">
        </div>
        <div class="grid grid-cols-2 gap-2">
            <input type="number" x-model="totalMarks" min="1" class="border rounded px-2 py-1.5 text-sm" placeholder="Total marks">
            <select x-model="mix" class="border rounded px-2 py-1.5 text-sm">
                <option value="mixed">Mixed (MCQ + written)</option>
                <option value="mcq_only">All MCQ</option>
                <option value="written_only">All written</option>
            </select>
        </div>
        <button type="button" @click="generateWithAi(materialId, range, totalMarks, mix)" :disabled="aiLoading"
                class="text-sm bg-slate-800 text-white px-3 py-1.5 rounded hover:bg-slate-700 disabled:opacity-50">
            <span x-show="!aiLoading">Generate Draft from Material</span>
            <span x-show="aiLoading">Generating...</span>
        </button>
        <p class="text-xs text-red-600" x-text="aiError" x-show="aiError"></p>
        <p class="text-xs text-gray-400">This fills the questions below — review and edit before saving.</p>
    </div>
    {{-- =================== END AI DRAFT SECTION ===================== --}}

    <form method="POST" action="{{ route("teacher.quizzes.store", $course) }}" class="bg-white p-6 rounded shadow space-y-6">
        @csrf

        {{-- ===================== QUIZ META SECTION ===================== --}}
        <div class="grid grid-cols-2 gap-4">
            <div class="col-span-2">
                <label class="block text-sm font-medium mb-1">Quiz Title</label>
                <input type="text" name="title" class="w-full border rounded px-3 py-2" required>
            </div>
            <div>
                <label class="block text-sm font-medium mb-1">Available From</label>
                <input type="datetime-local" name="available_from" class="w-full border rounded px-3 py-2" required>
            </div>
            <div>
                <label class="block text-sm font-medium mb-1">Available Until</label>
                <input type="datetime-local" name="available_until" class="w-full border rounded px-3 py-2" required>
            </div>
        </div>
        {{-- =================== END QUIZ META SECTION ===================== --}}

        {{-- ===================== QUESTIONS SECTION ===================== --}}
        <div class="space-y-4">
            <template x-for="(q, i) in questions" :key="i">
                <div class="border rounded p-4 space-y-2">
                    <div class="flex justify-between">
                        <span class="text-sm font-medium">Question <span x-text="i + 1"></span></span>
                        <button type="button" @click="questions.splice(i, 1)" class="text-red-600 text-sm" x-show="questions.length > 1">Remove</button>
                    </div>
                    <input type="text" :name="`questions[${i}][question_text]`" x-model="q.question_text" placeholder="Question text" class="w-full border rounded px-3 py-2" required>
                    <div class="grid grid-cols-2 gap-2">
                        <select :name="`questions[${i}][type]`" x-model="q.type" class="border rounded px-3 py-2">
                            <option value="mcq">MCQ</option>
                            <option value="short">Short Answer</option>
                        </select>
                        <input type="number" :name="`questions[${i}][marks]`" x-model="q.marks" min="1" placeholder="Marks" class="border rounded px-3 py-2" required>
                    </div>
                    <template x-if="q.type === 'mcq'">
                        <div class="grid grid-cols-2 gap-2">
                            <template x-for="(opt, oi) in q.options" :key="oi">
                                <input type="text" :name="`questions[${i}][options][${oi}]`" x-model="q.options[oi]" :placeholder="`Option ${oi + 1}`" class="border rounded px-3 py-2">
                            </template>
                        </div>
                    </template>
                    <input type="text" :name="`questions[${i}][correct_answer]`" x-model="q.correct_answer" placeholder="Correct answer (exact text)" class="w-full border rounded px-3 py-2" required>
                </div>
            </template>
            <button type="button" @click="questions.push({question_text: '', type: 'mcq', options: ['', '', '', ''], correct_answer: '', marks: 1})"
                    class="text-sm text-slate-800 border border-slate-800 px-3 py-1.5 rounded hover:bg-slate-50">
                + Add Question
            </button>
        </div>
        {{-- =================== END QUESTIONS SECTION ===================== --}}

        <button type="submit" class="w-full bg-slate-800 text-white py-2 rounded hover:bg-slate-700">
            Generate Quiz & Notify Students
        </button>
    </form>
</div>
@endsection
