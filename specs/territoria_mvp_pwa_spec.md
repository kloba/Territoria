# Territoria – MVP Specification (Final)

A concise spec for a **Paper.io–style, GPS-based** territory game prototype built with **Flutter Web as a PWA**, using `CustomPaint` to render game graphics (zones, trails, player) over the map.

---

## 1) Scope
- Single player, on-device only.
- Real GPS movement; no background mode.
- Territory capture occurs when player **returns into their own zone** with a trail drawn outside it.
- No enemies, accounts, or server sync.

---

## 2) Game Loop & State
- **States:** `InsideZone` → `OutsideZoneCapturing` → `ReturnToZone` → `Capture` → `InsideZone`.
- Start inside current zone (initially a small circle around spawn).
- Exiting the zone starts a **trail**; re-entering the zone triggers **capture** if the trail forms a valid loop.

> Optional (config flag `captureMode=self_overlap`): allow capture when the trail **self-overlaps** to form a loop (default off to stay true to Paper.io).

---

## 3) Core Mechanics (Paper.io–style)
- **Trail:** drawn only while outside the owned zone.
- **Capture trigger:** when crossing back into the zone boundary with a valid trail.
- **Captured area:** the polygon enclosed by the trail **plus** the boundary segment of the owned zone connecting entry/exit points; unioned into the owned zone.
- **Loss/reset conditions (MVP):** none (no enemies). If GPS accuracy becomes poor, trail points are paused.

---

## 4) Map & Rendering
- Basemap centered on **user geolocation** (OpenStreetMap tiles via `flutter_map` with gestures off, or pre-rendered raster image tiles).
- Above the map, a **`CustomPaint`** layer renders:
  - Owned zone (filled polygon)
  - Current trail (polyline)
  - Player marker (dot with heading optional)
- Coordinate transforms: LatLng ↔ screen points handled in a single projection helper.

---

## 5) GPS & Sampling
- **Packages:** `geolocator`, `permission_handler`.
- **Update rate:** 1 Hz while capturing; reduced when stationary using distance filter.
- **Filters:**
  - Discard points with accuracy > 20 m.
  - Ignore points < 3 m from last kept point.
  - Optional smoothing: moving average (window 5).

---

## 6) Geometry & Validation
- **Libraries:** `turf_dart` for line/polygon ops, area, unions/differences.
- **Trail validity:**
  - ≥ 10 vertices after simplification (Douglas–Peucker tolerance 3 m).
  - Resulting capture polygon area ≥ 150 m².
  - No invalid self-intersections (except at the closure point with zone boundary).
- **Capture operation:**
  1. Detect **boundary re-entry** (segment crosses zone polygon edge to inside).
  2. Build capture polygon from trail + appropriate zone boundary arc.
  3. Validate & simplify; compute area.
  4. **Union** with existing owned zone; persist.

---

## 7) UI / UX
- **Overlay controls:**
  - `Undo Trail` (clears current trail)
  - Stats panel toggle
- **Indicators:**
  - GPS accuracy (bars or numeric)
  - Trail length (m)
  - Candidate area during return (m²)
- **Toasts:**
  - "Capture started" / "Returned to zone – area captured" / "Invalid loop (too small/shape invalid)".

---

## 8) Statistics (Daily)
- **Distance (km):** sum of Haversine segment lengths / 1000.
- **Steps:** `distance_m / stride_length_m` (default 0.75 m; user-adjustable).
- **Area (km²):** sum(owned zone area) / 1e6.
- Display as compact overlay; reset at midnight local; persist historical totals (optional).

---

## 9) Data & Storage
- **Packages:** `hive`, `hive_flutter`, `hive_web` (for PWA)
- **Entities:**
```dart
class CapturedZone {
  final List<LatLng> polygon;
  final DateTime timestamp;
  final double areaM2;
}
class DailyStats {
  final DateTime day;
  final double distanceKm;
  final int steps;
  final double areaKm2;
}
class Settings {
  final double strideLengthM; // default 0.75
  final String captureMode;   // "return_to_zone" (default) | "self_overlap"
}
```
- Export owned zone as **GeoJSON** (nice-to-have).

---

## 10) Performance & Battery
- Track GPS **only** during capture or when inside zone with motion detected.
- Debounce repaints to ≤ 10 fps.
- Cache map tiles if using `flutter_map_tile_caching` (optional).

---

## 11) Platform & Deployment
- Built as a **Progressive Web App (PWA)** using Flutter Web.
- Deployed via HTTPS with a valid service worker and PWA manifest.
- Data stored via `hive_web` using IndexedDB.
- Compatible with mobile browsers and installable on home screen (Android/iOS).

---

## 12) Permissions & Privacy
- On app launch, the user is prompted to grant **location access** (foreground only).
- Must support permission flow for both **Android** and **iOS** platforms.
- Use `permission_handler` to check/request and handle denied or limited permissions.
- App must degrade gracefully if location is not granted (e.g. show fallback screen with explanation).

---

## 13) Acceptance Criteria
- App centers on user and shows owned zone + marker.
- Leaving the zone starts a trail; re-entering captures area and grows the zone.
- Geometry validation prevents tiny/invalid captures.
- Daily stats show distance, steps, and area; persist across restarts.
- Smooth rendering; UI remains responsive; no crashes on permission denial (graceful fallback).

---

## 14) Milestones
1. **Map + Permissions + Marker**
2. **Trail Recording + Filtering**
3. **Boundary Re-entry Detection**
4. **Capture Polygon Build + Union**
5. **Stats + Persistence**
6. **Polish (toasts, settings, export)**
