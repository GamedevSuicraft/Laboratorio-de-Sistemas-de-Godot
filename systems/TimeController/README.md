# Time Controller System

A flexible in-game 24-hour day/night cycle manager that tracks time progression and drives environment lighting, shaders, or clock displays.

---

## 📄 Scripts & Scenes

* `TimeController.gd` (`Node`): Logic calculating progression of 86,400 seconds (one full day) mapped to customizable real-world minutes.
* `TimeController.tscn`: Node scene ready to drag-and-drop into the scene tree or autoload.

---

## ⚙️ Inspector Properties

* `day_duration_minutes: float = 10.0`: The duration of an entire 24-hour in-game day in real-world minutes.
* `time_of_day: float`: Current time of the day in seconds (`0.0` to `86400.0`). Default starts at midday (`43200.0`).
* `debug_time: bool = false`: When enabled, outputs formatted `%02d:%02d` time logs to the console every frame.

---

## 📡 Signals

* `time_changed(current_time: float)`: Emitted every frame in `_process()`, passing the raw elapsed seconds of the day (`0.0` to `86400.0`).

---

## 🛠️ Utility Methods

* `get_normalized_time() -> float`: Returns time mapped to `[0.0, 1.0]` where `0.5` represents midday. Ideal for driving directional light rotations and sky shaders!
* `get_hours() -> int`: Current clock hour (`0` to `23`).
* `get_minutes() -> int`: Current clock minute (`0` to `59`).
* `set_time_with_clock_time(hours: int, minutes: int) -> void`: Sets the clock immediately to a specific time.

---

## 🧪 Usage Example

Synchronizing a 3D `DirectionalLight3D` (sun) and UI clock:

```gdscript
extends Node3D

@onready var time_controller: TimeController = $TimeController
@onready var sun_light: DirectionalLight3D = $DirectionalLight3D
@onready var clock_label: Label = $CanvasLayer/ClockLabel

func _ready() -> void:
    time_controller.time_changed.connect(_on_time_changed)

func _on_time_changed(_current_time: float) -> void:
    # 1. Update clock UI
    clock_label.text = "%02d:%02d" % [time_controller.get_hours(), time_controller.get_minutes()]
    
    # 2. Rotate sun based on normalized time [0.0..1.0]
    var normalized = time_controller.get_normalized_time()
    sun_light.rotation.x = deg_to_rad((normalized * 360.0) - 90.0)
```
