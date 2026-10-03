<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>@yield("title", "Course LMS")</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script defer src="https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js"></script>
</head>
<body class="bg-gray-100 min-h-screen">

    {{-- ===================== NAVBAR SECTION ===================== --}}
    <nav class="bg-slate-800 text-white">
        <div class="max-w-6xl mx-auto px-4 py-3 flex items-center justify-between">
            <span class="font-semibold">Course LMS</span>
            @auth
                <div class="flex items-center gap-4 text-sm">
                    <span class="text-slate-300">{{ auth()->user()->name }} ({{ auth()->user()->role }})</span>
                    <form method="POST" action="{{ route("logout") }}">
                        @csrf
                        <button class="bg-slate-700 hover:bg-slate-600 px-3 py-1.5 rounded">Logout</button>
                    </form>
                </div>
            @endauth
        </div>
    </nav>
    {{-- =================== END NAVBAR SECTION ===================== --}}

    {{-- ===================== STATUS / ERROR SECTION ===================== --}}
    <div class="max-w-6xl mx-auto px-4 pt-4">
        @if (session("status"))
            <div class="bg-green-100 border border-green-300 text-green-800 px-4 py-3 rounded mb-4">
                {{ session("status") }}
            </div>
        @endif

        @if ($errors->any())
            <div class="bg-red-100 border border-red-300 text-red-800 px-4 py-3 rounded mb-4">
                <ul class="list-disc list-inside">
                    @foreach ($errors->all() as $error)
                        <li>{{ $error }}</li>
                    @endforeach
                </ul>
            </div>
        @endif
    </div>
    {{-- =================== END STATUS / ERROR SECTION ===================== --}}

    {{-- ===================== PAGE CONTENT SECTION ===================== --}}
    <main class="max-w-6xl mx-auto px-4 pb-12">
        @yield("content")
    </main>
    {{-- =================== END PAGE CONTENT SECTION ===================== --}}

</body>
</html>
