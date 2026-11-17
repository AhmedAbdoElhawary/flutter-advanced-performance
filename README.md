# flutter_advanced_performance

Small Flutter demos that measure performance ideas instead of guessing.

Each demo runs the same work in two ways and shows the numbers side by side, so you can see what actually changes on a real device.

## Demos

| Demo | What it compares | Folder |
| --- | --- | --- |
| List VS Float64 | `List<double>` vs `Float64List` for storing numbers in a hot loop | [lib/list_vs_float64](lib/list_vs_float64/README.md) |

Open the app, pick a demo from the home page, and watch the stats row.

## Run it

Measure in profile mode on real hardware. Debug builds, simulators and emulators don't show real performance.

```sh
flutter pub get
flutter run --profile            # on a connected phone
flutter run -d macos --profile   # on a Mac
```

Use DevTools (Performance and Memory views) to dig deeper into each demo.

## Project layout

```
lib/
  main.dart            app entry
  home_page.dart       list of demos
  scale.dart           ui scale extension on BuildContext
  list_vs_float64/     List<double> vs Float64List demo
```

Every new demo gets its own folder under `lib/` with its own README.
