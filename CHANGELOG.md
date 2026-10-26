# Changes to the MapplsUtils SDK for iOS

## 1.0.2 - 26 Oct, 2026

### Added

- MapplsUtils can now be installed via CocoaPods, in addition to Swift Package Manager.

## 1.0.1 - 16 Sep, 2026

### Added

- Tracking plugin: via-point leg gating. When a route has via points, the rider is confined to the current leg. A location beyond the next via point is clamped to it, tracking is held on arrival, and the host resumes with `proceedToNextWaypoint()`.
- Config flag `shouldWaitAtWaypoints` (default `true`) to toggle the hold.
- Delegate callbacks `didReachWaypoint` and `didResumeAfterWaypoint`.
- Properties `activeWaypoint` and `isWaitingAtWaypoint`.

### Fixed

- `shouldHidePolyline` no longer inverts its own meaning.
- Waypoint marker updates target the correct shape source.
- `stopTracking()` cancels pending simulation steps.
- Route layers are removed before their sources.
- Directions callbacks now run on the main thread.
- Removed several force-unwraps and an animator retain cycle that leaked display-link callbacks.

### Changed

- `update(with:duration:)` duration is documented in milliseconds.

## 1.0.0 - 23 Dec, 2025
- Initial Mappls release.
