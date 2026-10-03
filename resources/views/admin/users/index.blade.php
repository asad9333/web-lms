@extends("layouts.app")
@section("title", "Manage Users")
@section("content")
<div class="mt-8">
    <div class="flex items-center justify-between mb-6">
        <h1 class="text-2xl font-semibold">Teachers & Students</h1>
        <a href="{{ route("admin.users.create") }}" class="bg-slate-800 text-white px-4 py-2 rounded hover:bg-slate-700">
            + Add User
        </a>
    </div>

    {{-- ===================== USERS TABLE SECTION ===================== --}}
    <div class="bg-white rounded shadow overflow-x-auto">
        <table class="w-full text-sm">
            <thead class="bg-gray-50 text-left">
                <tr>
                    <th class="px-4 py-3">Registration #</th>
                    <th class="px-4 py-3">Name</th>
                    <th class="px-4 py-3">Role</th>
                    <th class="px-4 py-3">Must Change Password</th>
                    <th class="px-4 py-3"></th>
                </tr>
            </thead>
            <tbody>
                @foreach ($users as $user)
                    <tr class="border-t">
                        <td class="px-4 py-3">{{ $user->registration_number }}</td>
                        <td class="px-4 py-3">{{ $user->name }}</td>
                        <td class="px-4 py-3 capitalize">{{ $user->role }}</td>
                        <td class="px-4 py-3">{{ $user->must_change_password ? "Yes" : "No" }}</td>
                        <td class="px-4 py-3 text-right space-x-3">
                            <form method="POST" action="{{ route("admin.users.reset-password", $user) }}" class="inline"
                                  onsubmit="return confirm('Reset this password? They will have to set a new one on next login.')">
                                @csrf
                                <button class="text-slate-800 hover:underline">Reset Password</button>
                            </form>
                            <form method="POST" action="{{ route("admin.users.destroy", $user) }}" class="inline"
                                  onsubmit="return confirm('Remove this user?')">
                                @csrf @method("DELETE")
                                <button class="text-red-600 hover:underline">Remove</button>
                            </form>
                        </td>
                    </tr>
                @endforeach
            </tbody>
        </table>
    </div>
    {{-- =================== END USERS TABLE SECTION ===================== --}}

    <div class="mt-4">{{ $users->links() }}</div>
</div>
@endsection
