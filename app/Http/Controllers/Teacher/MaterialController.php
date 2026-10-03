<?php

namespace App\Http\Controllers\Teacher;

use App\Http\Controllers\Controller;
use App\Models\Course;
use Illuminate\Http\Request;

class MaterialController extends Controller
{
    public function store(Request $request, Course $course)
    {
        abort_unless($course->teacher_id === $request->user()->id, 403);

        $data = $request->validate([
            "title" => ["required", "string", "max:255"],
            "type" => ["required", "in:book,slides,pdf,other"],
            "file" => ["required", "file", "mimes:pdf,doc,docx,ppt,pptx", "max:20480"],
        ]);

        $path = $request->file("file")->store("course_materials/{$course->id}", "public");

        $course->materials()->create([
            "title" => $data["title"],
            "type" => $data["type"],
            "file_path" => $path,
        ]);

        return back()->with("status", "Material uploaded.");
    }

    public function destroy(Course $course, \App\Models\CourseMaterial $material)
    {
        abort_unless($course->teacher_id === auth()->id(), 403);
        abort_unless($material->course_id === $course->id, 404);

        \Illuminate\Support\Facades\Storage::disk("public")->delete($material->file_path);
        $material->delete();

        return back()->with("status", "Material removed.");
    }
}
