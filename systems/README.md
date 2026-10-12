# Standalone Systems

High-level, world- and environment-level game systems designed for rapid drag-and-drop integration in Godot 4.x.

Unlike components (which are small building blocks attached to characters), systems represent higher-level gameplay mechanics, cameras, spawning routines, and world state controllers.

---

## 📁 Systems Overview

* [`Button/`](Button/README.md):
  * Physical interactive 3D pressure plate system with smooth tween animations and body counters.
  * **Test Reference**: [`tests/3d test/Button.tscn`](../tests/3d%20test/Button.tscn).
* [`Camera/`](Camera/README.md):
  * `SmoothCamera` (2D): Smart platformer camera with deadzones, directional look-ahead drift, and visual debug shapes. (Tested in [`tests/2d test/TestScene.tscn`](../tests/2d%20test/TestScene.tscn)).
  * `ThirdPersonCamera` (3D): SpringArm3D orbit camera with mouse capturing, vertical clamping, and character mesh rotation modes. (Tested in [`tests/3d test/Player3D.tscn`](../tests/3d%20test/Player3D.tscn)).
* [`Spawner/`](Spawner/README.md):
  * `Spawner2D`: Periodic and on-demand spawning inside rectangles, circles, or collision polygons.
  * `Spawner3D`: Periodic and on-demand spawning inside boxes, spheres, or cylinders.
* [`TimeController/`](TimeController/README.md):
  * 24-hour day/night in-game clock emitting time change signals and normalized [0.0..1.0] cycle values for lighting/shaders.
