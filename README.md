# MapplsUtils

MapplsUtils is a collection of iOS helper components for Mappls SDKs. Its main component is the
**Tracking Plugin**, which tracks a device along a route and animates the travelled path smoothly on
the map. 

## Table of contents

- [Requirements](#requirements)
- [Version history](#version-history)
- [Dependencies](#dependencies)
- [Installation](#installation)
- [Authorization](#authorization)
- [Tracking Plugin](#tracking-plugin)
  - [Initialization](#initialization)
  - [Configuration](#configuration)
  - [Via points and leg gating](#via-points-and-leg-gating)
  - [Methods](#methods)
  - [Properties](#properties)
  - [Delegate methods](#delegate-methods)
  - [3D rider marker](#3d-rider-marker)
  - [Complete example](#complete-example)
- [MapplsLocationAnimator](#mapplslocationanimator)
- [License](#license)

## Requirements

| | |
| :---- | :---- |
| Platform | iOS 13.0 or later |
| Distribution | Swift Package Manager, CocoaPods |

## Version history

| Version | Dated | Description |
| :---- | :---- | :---- |
| `1.0.2` | 26 Oct, 2026 | CocoaPods installation support. |
| `1.0.1` | 16 Sep, 2026 | Via-point leg gating; fixes. |
| `1.0.0` | 16 Sep, 2026 | Initial MapplsUtils release. |

## Dependencies

MapplsUtils requires the following Mappls libraries at runtime:

- [MapplsAPICore](https://github.com/MapmyIndia/mappls-api-core-distribution.git) (1.0.18)
- [MapplsAPIKit](https://github.com/MapmyIndia/mappls-api-kit-distribution.git) (2.0.39)
- [MapplsMap](https://github.com/MapmyIndia/mappls-map-ios-distribution.git) (6.0.2)


## Installation

### Swift Package Manager

In Xcode, choose **File > Add Package Dependencies** and add each of the following, MapplsUtils last:

```
https://github.com/MapmyIndia/mappls-api-core-distribution.git
https://github.com/MapmyIndia/mappls-api-kit-distribution.git
https://github.com/MapmyIndia/mappls-map-ios-distribution.git
https://github.com/MapmyIndia/mappls-utils-ios-distribution.git
```

All four packages must be added. Skipping the first three produces link errors for missing Mappls
symbols when you build.

### CocoaPods

Add MapplsUtils to your `Podfile`:

```ruby
pod 'MapplsUtils'
```

Then run `pod install`. The Mappls dependencies (MapplsAPICore, MapplsAPIKit, MapplsMap) are
resolved automatically as pod dependencies.


## Authorization

Mappls keys must be set before you create a `MapplsTrackingPlugin` or a `MapplsMapView`; route
calculation and map style loading both fail without them. Key setup lives in MapplsAPICore rather
than in this package, so follow the setup documented
[here](https://github.com/MapmyIndia/mappls-api-core-distribution.git) and do it early in your
app lifecycle, typically in `application(_:didFinishLaunchingWithOptions:)`.

## Tracking Plugin

### Initialization

`MapplsTrackingPlugin` has two initializers. Both take a `MapplsTrackingPluginConfig` and an optional
`MapplsMapView`.

Use this one when you already have a `Route` to track against:

```swift
let config = MapplsTrackingPluginConfig()
let plugin = MapplsTrackingPlugin(mapView: mapView, route: selectedRoute, config: config)
```

Use this one when you don't have a route yet. The plugin requests one for you from the source,
destination, and optional via points:

```swift
let config = MapplsTrackingPluginConfig()
let plugin = MapplsTrackingPlugin(
    mapView: mapView,
    sourceLocation: startCoordinate,
    destinationLocation: endCoordinate,
    viaPoint: viaPoints,       // optional, defaults to nil
    config: config
)
```

The route request completes asynchronously. Implement
`mapplsTrackingPlugin(_:didRerouted:error:)` to learn when the route is ready, or when it failed.

### Configuration

`MapplsTrackingPluginConfig` is a struct. Create it with the default initializer, set what you need,
then pass it to the plugin.

```swift
var config = MapplsTrackingPluginConfig()
config.shouldShowTraveledRoute = true
config.bufferToReachDestination = 30
config.riderMarkerImage = UIImage(named: "my-rider-icon")

let plugin = MapplsTrackingPlugin(mapView: mapView, route: selectedRoute, config: config)
```

#### Route and rendering

| Property | Type | Default | Description |
| :---- | :---- | :---- | :---- |
| `shouldShowTraveledRoute` | `Bool` | `false` | Draw a polyline for the portion of the route already travelled. |
| `shouldRemoveTraveledRoute` | `Bool` | `true` | Trim the travelled portion off the remaining-route polyline. |
| `shouldShowStartPointMarker` | `Bool` | `true` | Show a marker at the route's starting point. |
| `enableDestinationRouteConnector` | `Bool` | `true` | Draw a connector from the last on-road route point to the exact destination coordinate. |
| `enableFitToBound` | `Bool` | `true` | Fit the camera to the route bounds. Setting this to `true` forces `allowMapToAnimate` to `false`. |
| `allowMapToAnimate` | `Bool` | `false` | Let the map animate along with the user's location. |
| `show3DMarker` | `Bool` | `false` | Use a 3D marker for the rider instead of a flat 2D marker. Requires extra wiring, see [3D rider marker](#3d-rider-marker). |

#### Rerouting and arrival

| Property | Type | Default | Description |
| :---- | :---- | :---- | :---- |
| `distanceToRecalculateRoute` | `Double` | `500` | Distance in metres the reported location may deviate from the route before a reroute is requested. |
| `bufferToReachDestination` | `Double` | `50` | Distance in metres within which the destination, or a via point, counts as reached. Triggers `didArriveAt` and `didReachWaypoint`. |
| `shouldWaitAtWaypoints` | `Bool` | `true` | Confine the rider to the current leg when via points are present. See [Via points and leg gating](#via-points-and-leg-gating). |
| `latentViz` | `Bool` | `false` | Smoother visualization when the rider jumps off-route. Costs an additional routing call. |
| `latentVizRadius` | `Bool` | `false` | Enables the radius behaviour for latent visualization. |

#### Marker images

Each defaults to an image bundled with MapplsUtils. All are `UIImage?`.

| Property | Default image |
| :---- | :---- |
| `riderMarkerImage` | `carplayNavigationMarkerDay` |
| `sourceMarkerImage` | `source-location-pin` |
| `destinationMarkerImage` | `destinationReached` |
| `viaPointMarkerImage` | `viapoint-image` |

#### Simulation


| Property | Type | Default | Description |
| :---- | :---- | :---- | :---- |
| `enableSimulation` | `Bool` | `false` | Simulate location updates along the route. |
| `maxSimulationDistance` | `Double` | `100` | Maximum simulated distance from the start point, in metres. |
| `simulationSpeed` | `Double` | `1` | Simulated speed in metres per second. |
| `simulationStepDivisor` | `Double` | `10.0` | Factor by which simulated distance and speed are divided into steps. |

#### Coordinates

| Property | Type | Description |
| :---- | :---- | :---- |
| `sourceLocation` | `CLLocationCoordinate2D?` | Optional source coordinate carried on the config. |
| `waypointsLocation` | `[CLLocationCoordinate2D]?` | Optional via points carried on the config. |
| `destinationLocation` | `CLLocationCoordinate2D?` | Optional destination coordinate carried on the config. |

> The initializers take source, destination, and via points as their own arguments. These config
> properties are separate carriers for the same values and are not read by the initializers.

### Via points and leg gating

A route with via points is a sequence of legs. When `config.shouldWaitAtWaypoints` is `true`, which is
the default, the rider cannot leave the current leg until you say so:

1. A location you feed in that lies **beyond** the next via point is clamped to that via point. The
   marker animates up to it and stops there rather than skipping past it.
2. On reaching it, the plugin holds tracking and calls
   `mapplsTrackingPlugin(_:didReachWaypoint:at:remainingWaypoints:)`. While held, every
   `update(with:duration:)` is ignored, and simulated movement is cancelled.
3. You release the hold by calling `proceedToNextWaypoint()`. That marks the via point as visited and
   calls `mapplsTrackingPlugin(_:didResumeAfterWaypoint:remainingWaypoints:)`.
4. Once no via points are left, `didArriveAt` can fire for the destination. It does not fire while any
   via point is still unvisited.

Use the hold for whatever has to happen at the via point — a pickup, a delivery confirmation, a
signature — and resume when that is done.

```swift
var config = MapplsTrackingPluginConfig()
config.shouldWaitAtWaypoints = true     // default

let plugin = MapplsTrackingPlugin(
    mapView: mapView,
    sourceLocation: startCoordinate,
    destinationLocation: endCoordinate,
    viaPoint: [viaCoordinate],
    config: config
)
plugin.delegate = self
```

```swift
extension ViewController: MapplsTrackingPluginDelegate {

    func mapplsTrackingPlugin(_ mapView: MapplsMapView?,
                              didReachWaypoint coordinate: CLLocationCoordinate2D,
                              at index: Int,
                              remainingWaypoints: Int) {
        // Tracking is held here. Stop your own location feed too, otherwise it keeps
        // producing updates the plugin will discard.
        isHoldingAtWaypoint = true
        showDeliveryConfirmation(forViaPointAt: index)
    }

    func mapplsTrackingPlugin(_ mapView: MapplsMapView?,
                              didResumeAfterWaypoint coordinate: CLLocationCoordinate2D,
                              remainingWaypoints: Int) {
        isHoldingAtWaypoint = false
        resumeLocationFeed()
    }
}

/// Called when the user confirms the stop.
func confirmationAccepted() {
    plugin.proceedToNextWaypoint()
}
```

The `index` passed to `didReachWaypoint` is the position in the via point array you handed to the
plugin, and it stays stable as earlier via points are consumed. Via point marker labels use the same
numbering, so a via point labelled "2" keeps that label for the whole trip.

Setting `shouldWaitAtWaypoints` to `false` turns the hold off. The via point is consumed
automatically the moment it is reached, `didReachWaypoint` still fires, and the rider carries on into
the next leg without waiting.

> Route deviation takes precedence over gating. Whether the rider is on the route is judged on the
> location you reported, not on the clamped one, so a rider who genuinely left the road still
> triggers a reroute. The unvisited via points are carried into the new route.

### Methods

**`update(with:duration:)`** feeds a new location into the plugin. Call it every time you receive a
location update from your own source, usually `CLLocationManager` or your backend.

- `location` — `CLLocationCoordinate2D`, the new location to animate to.
- `duration` — `Double`, the time over which to animate from the previous location to this one,
  **in milliseconds**. Defaults to `2000`, i.e. two seconds.

```swift
plugin.update(with: coordinate, duration: 2000)
```

While the rider is held at a via point, calls to this method are ignored. See
[Via points and leg gating](#via-points-and-leg-gating).

**`proceedToNextWaypoint()`** marks the via point the rider is waiting at as visited and resumes
tracking into the next leg. Call it after `didReachWaypoint`; until you do, location updates have no
effect.

**`stopTracking()`** ends tracking by stopping the location animation and cancelling any pending
simulation step. Layers and markers stay on the map; use `removeTrackingRoutes()` to clear those.

**`removeTrackingRoutes()`** removes the plugin's polylines and markers from the map style.

**`calculateDeviatedRoute(source:destingation:duration:completion:)`** moves the rider to an
off-route location for latent visualization. Calls `completion` with `false` when `config.latentViz`
is `false`.

**`isUserInSecondLeg(location:)`** returns `Bool`, indicating whether the given location has passed
the next via point. Informational only: leg progress is controlled by `shouldWaitAtWaypoints` and
`proceedToNextWaypoint()`, so this does not trigger a reroute on its own.

**`updateWaypointMarkerIcon()`** refreshes the waypoint marker icons on the current style.

### Properties

- **`config`** — the `MapplsTrackingPluginConfig` the plugin was created with. Read/write.
- **`delegate`** — a weak `MapplsTrackingPluginDelegate?` for handling plugin events and styling.
- **`distanceRemaninig`** — `Double?`, the distance left to the destination in metres. Read-only from
  outside the plugin (`public internal(set)`). Only meaningful once a route is available.
- **`shouldHidePolyline`** — `Bool`. Set to `true` to hide the plugin's route layers, `false` to show
  them. Defaults to `false`.
- **`markerView`** — `RotatablePointAnnotation?`, the annotation used for the rider marker.
- **`activeWaypoint`** — `CLLocationCoordinate2D?`, the via point that closes the current leg, i.e.
  the next one to be reached. `nil` once every via point has been visited.
- **`isWaitingAtWaypoint`** — `Bool`, `true` while the rider is held at a via point waiting for
  `proceedToNextWaypoint()`. Read-only from outside the plugin.

> `distanceRemaninig` is spelled as shown. The misspelling is in the public API surface.

### Delegate methods

Set `plugin.delegate` and conform to `MapplsTrackingPluginDelegate`. Every method has a default
implementation supplied by a protocol extension, so all of them are optional. Implement only the ones
you need.

#### Styling

**`routeIdentifier`** styles the main route polyline. The default is a blue line, 8pt wide, with
round caps and joins.

```swift
func mapplsTrackingPlugin(source: MGLShapeSource, routeIdentifier identifier: String) -> MGLLineStyleLayer
```

**`traveledPathIdentifier`** styles the travelled portion of the route. The default is a grey line,
8pt wide.

```swift
func mapplsTrackingPlugin(source: MGLShapeSource, traveledPathIdentifier identifier: String) -> MGLLineStyleLayer
```

**`waypointLayerIdentifier`** styles via point markers, including the numbered label.

```swift
func mapplsTrackingPlugin(source: MGLSource, waypointLayerIdentifier identifier: String) -> MGLSymbolStyleLayer
```

**`sourceMarkerIdentifier`** styles the source marker.

```swift
func mapplsTrackingPlugin(source: MGLSource, sourceMarkerIdentifier identifier: String) -> MGLSymbolStyleLayer
```

**`destinationMarkerIdentifier`** styles the destination marker.

```swift
func mapplsTrackingPlugin(source: MGLSource, destinationMarkerIdentifier identifier: String) -> MGLSymbolStyleLayer
```

**`riderMarkerIdentifier`** styles the rider marker. The default aligns icon rotation to the map so
the marker turns with the route.

```swift
func mapplsTrackingPlugin(source: MGLSource, riderMarkerIdentifier identifier: String) -> MGLSymbolStyleLayer
```

#### Route requests

**`routeOptions`** is called each time the plugin requests a route, letting you customize the
request.

```swift
func mapplsTrackingPlugin(for routeOptions: RouteOptions) -> RouteOptions
```

> The default implementation sets `profileIdentifier = .biking` and `routeShapeResolution = .full`.
> If you are tracking anything other than a bike, implement this method and set the profile you want.

#### Camera

**`cameraThatFit`** customizes the map camera as the rider moves. The default flies the camera to a
viewport fitting the remaining route, with 100pt vertical and 50pt horizontal padding.

```swift
func mapplsTrackingPlugin(cameraThatFit shape: MGLPolyline, mapView: MapplsMapView)
```

#### Tracking events

**`willRerouted`** is called just before a reroute is requested.

```swift
func mapplsTrackingPlugin(_ mapView: MapplsMapView?, willRerouted route: Route?)
```

**`didRerouted`** delivers the new route, or an error if the request failed. This also fires for the
initial route when you use the source/destination initializer.

```swift
func mapplsTrackingPlugin(_ mapView: MapplsMapView?, didRerouted route: Route?, error: NSError?)
```

**`didArriveAt`** is called when the rider comes within `config.bufferToReachDestination` of the
destination. It does not fire while any via point is still unvisited.

```swift
func mapplsTrackingPlugin(_ mapView: MapplsMapView?, didArriveAt coordinate: CLLocationCoordinate2D)
```

**`didReachWaypoint`** is called when the rider reaches the via point that closes the current leg.
`index` is its position in the via point array you passed to the plugin, `remainingWaypoints` is how
many are still to be visited after it. While `config.shouldWaitAtWaypoints` is `true` the rider is
held here until you call `proceedToNextWaypoint()`.

```swift
func mapplsTrackingPlugin(_ mapView: MapplsMapView?, didReachWaypoint coordinate: CLLocationCoordinate2D, at index: Int, remainingWaypoints: Int)
```

**`didResumeAfterWaypoint`** is called after `proceedToNextWaypoint()` released the rider and tracking
resumed into the next leg.

```swift
func mapplsTrackingPlugin(_ mapView: MapplsMapView?, didResumeAfterWaypoint coordinate: CLLocationCoordinate2D, remainingWaypoints: Int)
```

**`remainingDistanceDidChange`** reports the updated remaining distance to the destination, in
metres.

```swift
func mapplsTrackingPlugin(_ mapView: MapplsMapView?, remainingDistanceDidChange remaningDistance: Double?)
```

**`didUpdateLocation`** fires on every interpolated location produced during the animation between
two coordinates.

```swift
func didUpdateLocation(location: CLLocation, valueAnimator: MapplsObjectAnimator<CLLocationCoordinate2D, LatLngEvaluator>?)
```

**`onAnimationStart`** and **`onAnimationEnd`** fire when the animation between two coordinates
starts and ends.

```swift
func onAnimationStart(animator: MapplsObjectAnimator<CLLocationCoordinate2D, LatLngEvaluator>)
func onAnimationEnd(animator: MapplsObjectAnimator<CLLocationCoordinate2D, LatLngEvaluator>)
```

### 3D rider marker

Setting `config.show3DMarker = true` is not enough on its own. The 3D marker is an
`MGLAnnotationView`, so your `MapplsMapViewDelegate` has to hand annotation views back to the plugin:

```swift
extension ViewController: MapplsMapViewDelegate {
    func mapView(_ mapView: MGLMapView, viewFor annotation: any MGLAnnotation) -> MGLAnnotationView? {
        return plugin.mapView(mapView, viewFor: annotation)
    }
}
```

Also forward camera changes so the marker keeps its orientation while the map moves:

```swift
func mapViewRegionIsChanging(_ mapView: MGLMapView) {
    plugin.regionIsChanging(mapView: mapView)
}
```

### Complete example

Tracking a device along a fixed, already-calculated route:

```swift
import UIKit
import MapplsMap
import MapplsAPIKit
import MapplsUtils

class ViewController: UIViewController {

    private var mapView: MapplsMapView!
    private var plugin: MapplsTrackingPlugin!

    /// The route to track along, obtained from your own Directions request
    /// or passed in from the previous screen.
    var selectedRoute: Route!

    override func viewDidLoad() {
        super.viewDidLoad()

        mapView = MapplsMapView(frame: view.bounds)
        mapView.delegate = self
        view.addSubview(mapView)

        var config = MapplsTrackingPluginConfig()
        config.shouldShowTraveledRoute = true
        config.bufferToReachDestination = 30

        plugin = MapplsTrackingPlugin(mapView: mapView, route: selectedRoute, config: config)
        plugin.delegate = self
    }

    /// Call this from your location source on every update. Duration is in milliseconds.
    func handleLocationUpdate(_ coordinate: CLLocationCoordinate2D) {
        plugin.update(with: coordinate, duration: 2000)
    }
}

extension ViewController: MapplsTrackingPluginDelegate {

    func mapplsTrackingPlugin(_ mapView: MapplsMapView?, didArriveAt coordinate: CLLocationCoordinate2D) {
        plugin.stopTracking()
        plugin.removeTrackingRoutes()
    }

    /// Only relevant for routes with via points. The rider is held here until
    /// `proceedToNextWaypoint()` is called.
    func mapplsTrackingPlugin(_ mapView: MapplsMapView?,
                              didReachWaypoint coordinate: CLLocationCoordinate2D,
                              at index: Int,
                              remainingWaypoints: Int) {
        print("Reached via point \(index + 1), \(remainingWaypoints) left")
        plugin.proceedToNextWaypoint()
    }

    func mapplsTrackingPlugin(_ mapView: MapplsMapView?, remainingDistanceDidChange remaningDistance: Double?) {
        guard let remaining = remaningDistance else { return }
        print("Remaining: \(remaining) m")
    }
}

extension ViewController: MapplsMapViewDelegate {}
```

If you don't have a route yet, swap the initializer for the source/destination form and wait for
`didRerouted` before you start feeding updates.

## MapplsLocationAnimator

`MapplsLocationAnimator` animates a location along a series of coordinates. The tracking plugin uses
it internally; use it directly when you want the animation without the rest of the plugin.

### Initialization

```swift
let animator = MapplsLocationAnimator()
animator.delegate = self
```

### Methods

**`animateLocation(coordinates:duration:)`** animates through the given coordinates.

- `coordinates` — `[CLLocationCoordinate2D]`, the path the animation follows.
- `duration` — `Double`, total duration of the animation in seconds.

```swift
animator.animateLocation(coordinates: coordinates, duration: 2)
```

### Properties

- **`delegate`** — a weak `MapplsLocationAnimatorDelegate?`.
- **`valueAnimator`** — the underlying `MapplsObjectAnimator<CLLocationCoordinate2D, LatLngEvaluator>?`.
  Call `end()` on it to stop an in-flight animation.

### Delegate methods

`MapplsLocationAnimatorDelegate` has no default implementations, so all three methods are required.

```swift
/// Fires on every interpolated location between two coordinates.
func didUpdateLocation(location: CLLocation)

/// Fires when the animation between two coordinates begins.
func onAnimationStart(animator: MapplsObjectAnimator<CLLocationCoordinate2D, LatLngEvaluator>)

/// Fires when the animation between two coordinates completes.
func onAnimationEnd(animator: MapplsObjectAnimator<CLLocationCoordinate2D, LatLngEvaluator>)
```

## License

MapplsUtils is released under the BSD 3-Clause License. See [LICENSE.md](LICENSE.md) for the full
terms.

MAPPLS © Copyright CE Info Systems Pvt. Ltd. All rights reserved.
