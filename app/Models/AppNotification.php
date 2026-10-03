<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AppNotification extends Model
{
    protected $table = "app_notifications";

    protected $fillable = ["user_id", "title", "message", "type", "related_id", "read_at"];

    protected function casts(): array
    {
        return [
            "read_at" => "datetime",
        ];
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
