# flutter_advanced_performance
 
Small Flutter demos that measure performance ideas instead of guessing.
 
## List<double> vs Float64List
 
`lib/list_vs_float64/` moves a field of dots in a circle. Each frame runs 64 small steps, and each step updates the `x` and `y` of every dot.
 
There are two versions of the same simulation:
 
- `ListSimulation` stores the numbers in `List<double>` (fixed-length).
- `FloatSimulation` stores them in `Float64List`.
The loops are the same code. Only the storage type changes. Pick a version with the buttons and a dot count with the slider.
 
The stats row shows:
 
- **FPS**: frames per second, capped by your screen's refresh rate.
- **sim ms / frame**: the measured time of the simulation step in each frame (Stopwatch around `step()`). This keeps showing a difference even when both versions hit the FPS cap.
## Run it
 
Measure in profile mode on real hardware. Debug builds and simulators or emulators don't show real performance.
 
```sh
flutter run --profile            # on a connected phone
flutter run -d macos --profile   # on a Mac
```
 
To see the allocations, open DevTools, go to the Memory view, and trace instances of the class `_Double` for each version.
 