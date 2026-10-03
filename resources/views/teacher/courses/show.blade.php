@extends("layouts.app")
@section("title", $course->title)
@section("content")
<div class="mt-8 space-y-8" x-data="{ tab: 'materials' }">
    <div>
        <h1 class="text-2xl font-semibold">{{ $course->title }}</h1>
        <p class="text-gray-500">{{ $course->description }}</p>
    </div>

    {{-- ===================== TABS NAV SECTION ===================== --}}
    <div class="flex gap-2 border-b">
        <button @click="tab = 'materials'" :class="tab === 'materials' ? 'border-b-2 border-slate-800 font-medium' : 'text-gray-500'" class="px-3 py-2">Materials</button>
        <button @click="tab = 'syllabus'" :class="tab === 'syllabus' ? 'border-b-2 border-slate-800 font-medium' : 'text-gray-500'" class="px-3 py-2">Syllabus</button>
        <button @click="tab = 'quizzes'" :class="tab === 'quizzes' ? 'border-b-2 border-slate-800 font-medium' : 'text-gray-500'" class="px-3 py-2">Quizzes</button>
        <button @click="tab = 'assignments'" :class="tab === 'assignments' ? 'border-b-2 border-slate-800 font-medium' : 'text-gray-500'" class="px-3 py-2">Assignments</button>
        <button @click="tab = 'students'" :class="tab === 'students' ? 'border-b-2 border-slate-800 font-medium' : 'text-gray-500'" class="px-3 py-2">
            Students
            @if ($course->pendingStudents->count())
                <span class="ml-1 bg-amber-500 text-white text-xs rounded-full px-1.5 py-0.5">{{ $course->pendingStudents->count() }}</span>
            @endif
        </button>
    </div>
    {{-- =================== END TABS NAV SECTION ===================== --}}

    {{-- ===================== MATERIALS TAB SECTION ===================== --}}
    <div x-show="tab === 'materials'" class="bg-white p-5 rounded shadow space-y-4">
        <h2 class="font-semibold">Upload Study Material</h2>
        <form method="POST" action="{{ route("teacher.materials.store", $course) }}" enctype="multipart/form-data" class="grid grid-cols-3 gap-3 items-end">
            @csrf
            <div class="col-span-1">
                <label class="block text-sm mb-1">Title</label>
                <input type="text" name="title" class="w-full border rounded px-2 py-1.5" required>
            </div>
            <div class="col-span-1">
                <label class="block text-sm mb-1">Type</label>
                <select name="type" class="w-full border rounded px-2 py-1.5" required>
                    <option value="book">Book</option>
                    <option value="slides">Slides</option>
                    <option value="pdf">PDF</option>
                    <option value="other">Other</option>
                </select>
            </div>
            <div class="col-span-1">
                <label class="block text-sm mb-1">File</label>
                <input type="file" name="file" class="w-full border rounded px-2 py-1.5" required>
            </div>
            <div class="col-span-3">
                <button class="bg-slate-800 text-white px-4 py-1.5 rounded hover:bg-slate-700">Upload</button>
            </div>
        </form>

        <ul class="divide-y">
            @forelse ($course->materials as $material)
                <li class="py-2 flex items-center justify-between text-sm">
                    <a href="{{ Storage::url($material->file_path) }}" target="_blank" class="text-slate-800 hover:underline">
                        {{ $material->title }} <span class="text-gray-400">({{ $material->type }})</span>
                    </a>
                    <form method="POST" action="{{ route("teacher.materials.destroy", [$course, $material]) }}">
                        @csrf @method("DELETE")
                        <button class="text-red-600 hover:underline">Delete</button>
                    </form>
                </li>
            @empty
                <li class="py-2 text-gray-500 text-sm">No material uploaded yet.</li>
            @endforelse
        </ul>
    </div>
    {{-- =================== END MATERIALS TAB SECTION ===================== --}}

    {{-- ===================== SYLLABUS TAB SECTION ===================== --}}
    <div x-show="tab === 'syllabus'" class="bg-white p-5 rounded shadow space-y-4">
        <h2 class="font-semibold">Syllabus Outline</h2>
        <form method="POST" action="{{ route("teacher.syllabus.store", $course) }}" class="grid grid-cols-4 gap-3 items-end">
            @csrf
            <div><label class="block text-sm mb-1">Week #</label><input type="number" name="week_number" min="1" class="w-full border rounded px-2 py-1.5" required></div>
            <div class="col-span-2"><label class="block text-sm mb-1">Topic</label><input type="text" name="topic" class="w-full border rounded px-2 py-1.5" required></div>
            <div>
                <label class="block text-sm mb-1">Phase</label>
                <select name="phase" class="w-full border rounded px-2 py-1.5" required>
                    <option value="before_mid">Before Mid</option>
                    <option value="before_final">Before Final</option>
                </select>
            </div>
            <div class="col-span-4"><button class="bg-slate-800 text-white px-4 py-1.5 rounded hover:bg-slate-700">Add Week</button></div>
        </form>

        <table class="w-full text-sm">
            <thead class="text-left text-gray-500"><tr><th class="py-1">Week</th><th>Topic</th><th>Phase</th><th>Status</th><th></th></tr></thead>
            <tbody>
                @foreach ($course->syllabus as $item)
                    <tr class="border-t">
                        <td class="py-2">{{ $item->week_number }}</td>
                        <td>{{ $item->topic }}</td>
                        <td>{{ $item->phase === "before_mid" ? "Before Mid" : "Before Final" }}</td>
                        <td>{{ $item->is_covered ? "Covered" : "Pending" }}</td>
                        <td>
                            @unless ($item->is_covered)
                                <form method="POST" action="{{ route("teacher.syllabus.cover", [$course, $item]) }}">
                                    @csrf
                                    <button class="text-slate-800 hover:underline">Mark covered</button>
                                </form>
                            @endunless
                        </td>
                    </tr>
                @endforeach
            </tbody>
        </table>
    </div>
    {{-- =================== END SYLLABUS TAB SECTION ===================== --}}

    {{-- ===================== QUIZZES TAB SECTION ===================== --}}
    <div x-show="tab === 'quizzes'" class="bg-white p-5 rounded shadow space-y-4">
        <div class="flex items-center justify-between">
            <h2 class="font-semibold">Quizzes</h2>
            <a href="{{ route("teacher.quizzes.create", $course) }}" class="bg-slate-800 text-white px-3 py-1.5 rounded text-sm hover:bg-slate-700">Generate Quiz</a>
        </div>
        <ul class="divide-y text-sm">
            @forelse ($course->quizzes as $quiz)
                <li class="py-2 flex items-center justify-between">
                    <span>{{ $quiz->title }} — {{ $quiz->available_from }} to {{ $quiz->available_until }}</span>
                    <a href="{{ route("teacher.quizzes.results", [$course, $quiz]) }}" class="text-slate-800 hover:underline">Results</a>
                </li>
            @empty
                <li class="py-2 text-gray-500">No quizzes yet.</li>
            @endforelse
        </ul>
    </div>
    {{-- =================== END QUIZZES TAB SECTION ===================== --}}

    {{-- ===================== ASSIGNMENTS TAB SECTION ===================== --}}
    <div x-show="tab === 'assignments'" class="bg-white p-5 rounded shadow space-y-4">
        <div class="flex items-center justify-between">
            <h2 class="font-semibold">Assignments</h2>
            <a href="{{ route("teacher.assignments.create", $course) }}" class="bg-slate-800 text-white px-3 py-1.5 rounded text-sm hover:bg-slate-700">Create Assignment</a>
        </div>
        <ul class="divide-y text-sm">
            @forelse ($course->assignments as $assignment)
                <li class="py-2 flex items-center justify-between">
                    <span>{{ $assignment->title }} — due {{ $assignment->available_until }}</span>
                    <a href="{{ route("teacher.assignments.submissions", [$course, $assignment]) }}" class="text-slate-800 hover:underline">Submissions</a>
                </li>
            @empty
                <li class="py-2 text-gray-500">No assignments yet.</li>
            @endforelse
        </ul>
    </div>
    {{-- =================== END ASSIGNMENTS TAB SECTION ===================== --}}

    {{-- ===================== STUDENTS TAB SECTION ===================== --}}
    <div x-show="tab === 'students'" class="space-y-6">

        {{-- Pending enrollment requests --}}
        @if ($course->pendingStudents->count())
            <div class="bg-white p-5 rounded shadow space-y-3">
                <h2 class="font-semibold flex items-center gap-2">
                    Pending Requests
                    <span class="bg-amber-100 text-amber-700 text-xs rounded-full px-2 py-0.5">{{ $course->pendingStudents->count() }}</span>
                </h2>
                <div class="grid sm:grid-cols-2 gap-3">
                    @foreach ($course->pendingStudents as $student)
                        <div class="border border-amber-200 bg-amber-50 rounded-lg p-4 flex items-center justify-between gap-3">
                            <div class="flex items-center gap-3 min-w-0">
                                <div class="w-10 h-10 rounded-full bg-amber-500 text-white flex items-center justify-center font-semibold shrink-0">
                                    {{ strtoupper(substr($student->name, 0, 1)) }}
                                </div>
                                <div class="min-w-0">
                                    <p class="font-medium truncate">{{ $student->name }}</p>
                                    <p class="text-xs text-gray-500">{{ $student->registration_number }}</p>
                                </div>
                            </div>
                            <div class="flex gap-2 shrink-0">
                                <form method="POST" action="{{ route("teacher.courses.students.approve", [$course, $student]) }}">
                                    @csrf
                                    <button class="bg-green-600 text-white text-xs px-3 py-1.5 rounded hover:bg-green-700">Approve</button>
                                </form>
                                <form method="POST" action="{{ route("teacher.courses.students.reject", [$course, $student]) }}">
                                    @csrf
                                    <button class="bg-red-100 text-red-700 text-xs px-3 py-1.5 rounded hover:bg-red-200">Reject</button>
                                </form>
                            </div>
                        </div>
                    @endforeach
                </div>
            </div>
        @endif

        {{-- Enrolled students --}}
        <div class="bg-white p-5 rounded shadow space-y-4">
            <div class="flex items-center justify-between">
                <h2 class="font-semibold">Enrolled Students</h2>
                <span class="text-sm text-gray-500">{{ $course->students->count() }} total</span>
            </div>

            @if ($course->students->count())
                <div class="grid sm:grid-cols-2 lg:grid-cols-3 gap-3">
                    @foreach ($course->students as $student)
                        <div class="border rounded-lg p-4 flex items-center justify-between gap-3">
                            <div class="flex items-center gap-3 min-w-0">
                                <div class="w-10 h-10 rounded-full bg-slate-800 text-white flex items-center justify-center font-semibold shrink-0">
                                    {{ strtoupper(substr($student->name, 0, 1)) }}
                                </div>
                                <div class="min-w-0">
                                    <p class="font-medium truncate">{{ $student->name }}</p>
                                    <p class="text-xs text-gray-500">{{ $student->registration_number }}</p>
                                </div>
                            </div>
                            <form method="POST" action="{{ route("teacher.courses.students.remove", [$course, $student]) }}" onsubmit="return confirm('Remove this student from the course?');">
                                @csrf @method("DELETE")
                                <button class="text-gray-400 hover:text-red-600 text-xs">Remove</button>
                            </form>
                        </div>
                    @endforeach
                </div>
            @else
                <div class="text-center py-10 text-gray-400">
                    <p class="text-sm">No students enrolled yet.</p>
                    <p class="text-xs mt-1">Students can find this course under "Browse Courses" on their dashboard and request to join — approved requests will show up here.</p>
                </div>
            @endif
        </div>
    </div>
    {{-- =================== END STUDENTS TAB SECTION ===================== --}}
</div>
@endsection
