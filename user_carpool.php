<?php
namespace Modules\TripManagement\Http\Controllers\Api\New\Customer;

use App\Jobs\SendPushNotificationJob;
use Doctrine\Common\Cache\Cache;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Routing\Controller;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\Validator as ValidationValidator;
use MatanYadaev\EloquentSpatial\Objects\Point;
use Modules\TripManagement\Entities\CarpoolPassenger;
use Modules\TripManagement\Entities\CarpoolRoute;
use Modules\TripManagement\Entities\TripRequest;
use Modules\TripManagement\Interfaces\TripRequestInterfaces;
use Modules\TripManagement\Service\Interface\TripRequestServiceInterface;
use Modules\TripManagement\Transformers\TripRequestResource;


class CarpoolingController extends Controller
{

protected $tripRequest;
protected $trip;

public function __construct(TripRequestServiceInterface $tripRequest,TripRequestInterfaces $trip)
{
    $this->tripRequest = $tripRequest;
    $this->trip = $trip;
}

	 public function joinTrip(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'route_id' => 'required|exists:carpool_routes,id',
            'pickup_lat' => 'required|numeric',
            'pickup_lng' => 'required|numeric',
            'dropoff_lat' => 'required|numeric',
            'dropoff_lng' => 'required|numeric',
            'seats_count' => 'required|integer|min:1|max:8',
            'fare' =>'required'
        ]);

        if ($validator->fails()) {
            return response()->json(responseFormatter(DEFAULT_400, errorProcessor($validator)), 403);
        }

        $route = CarpoolRoute::find($request->route_id);

        if ($route->seats_available < $request->seats_count) {
            return response()->json(responseFormatter(DEFAULT_400, ['message' => 'Not enough seats available']), 403);
        }

        $otp = rand(1000, 9999);
        $passenger = CarpoolPassenger::create([
            'carpool_route_id' => $route->id,
            'user_id' => auth()->id(),
            'pickup_location' => new Point($request->pickup_lat, $request->pickup_lng),
            'dropoff_location' => new Point($request->dropoff_lat, $request->dropoff_lng),
            'seats_count' => $request->seats_count,
            'otp' => $otp,
            'status' => 'pending',
             'fare'=> $request->fare,
             'driver_decision' => 'pending'
        ]);

        $route->decrement('seats_available', $request->seats_count);

        return response()->json(responseFormatter(DEFAULT_STORE_200, [
            'passenger_id' => $passenger->id,
            'otp' => $otp,
        ]));
    }

    public function matchPassengerOtp(Request $request): JsonResponse
    {
            $validator = Validator::make($request->all(), [
                'carpool_passenger_id' => 'required|exists:carpool_passengers,id',
                'otp' => 'required|string',
            ]);

            if ($validator->fails()) {
                return response()->json(responseFormatter(DEFAULT_400, errorProcessor($validator)), 403);
            }

            $passenger = CarpoolPassenger::where([
                'id' => $request->carpool_passenger_id,
                'user_id' => auth()->id(),
                'otp' => $request->otp
            ])->first();


            if (!$passenger) {
                return response()->json(responseFormatter(OTP_MISMATCH_404), 403);
            }

            $passenger->status = 'onboard';
            $passenger->arrived_at = now();
            $passenger->save();

            return response()->json(responseFormatter(DEFAULT_UPDATE_200));
    }

     public function getUserTrips(): JsonResponse
        {
            $userId = auth()->id();

            $trips = CarpoolPassenger::with(['route.user'])
                ->where('user_id', $userId)
                ->orderByDesc('created_at')
                ->get()
                ->map(function ($trip) {
                    $driver = $trip->route->user;
                    $startTime = $trip->route->start_time;
                    $pickupLocation = $trip->pickup_location;
                    $dropoffLocation = $trip->dropoff_location;
                    return [
                        'route_id' => $trip->carpool_route_id,
                        'driver_name' => $driver->full_name ?? 'غير معروف',
                        'driver_image' => $driver->profile_image ? asset('storage/' . $driver->profile_image) : null,
                        'start_day' => $startTime->format('Y-m-d'),
                        'start_hour' => $startTime->format('h:i A'),
                        'start_address' => $this->getAddressFromLatLng($pickupLocation->latitude, $pickupLocation->longitude),
                        'end_address' => $this->getAddressFromLatLng($dropoffLocation->latitude, $dropoffLocation->longitude),
                        'status' => $trip->driver_decision,
                    ];
                });

            return response()->json(responseFormatter(DEFAULT_200, $trips));
        }

 public function suggestDropoff(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'pickup_lat' => 'required|numeric',
            'pickup_lng' => 'required|numeric',
            'dropoff_lat' => 'required|numeric',
            'dropoff_lng' => 'required|numeric',
        ]);

        if ($validator->fails()) {
            return response()->json(responseFormatter(DEFAULT_400, errorProcessor($validator)), 403);
        }

        $route = CarpoolRoute::latest()->first();
        $points = json_decode($route->route_points, true);

        $isFar = !$this->isCloseToRoute($points, $request->dropoff_lat, $request->dropoff_lng, 5);

        if ($isFar) {
            $suggested = $this->getClosestPoint($points, $request->dropoff_lat, $request->dropoff_lng);
            return response()->json(responseFormatter(DEFAULT_200, [
                'suggested_dropoff' => $suggested,
                'note' => 'Your original drop-off is far. Please consider this nearby point.',
            ]));
        }

        return response()->json(responseFormatter(DEFAULT_200, [
            'message' => 'Your drop-off is acceptable',
        ]));
    }

    public function findMatchingRides(Request $request): JsonResponse
{
    $validator = Validator::make($request->all(), [
        'pickup_lat' => 'required|numeric',
        'pickup_lng' => 'required|numeric',
        'dropoff_lat' => 'required|numeric',
        'dropoff_lng' => 'required|numeric',
        'gender' => 'nullable|in:male,female,both',
        'seats_required' => 'nullable|integer|min:1|max:8',
        'ride_type' => 'nullable|string',
        'day' => 'required|date',
        'category' => 'nullable|string',
    ]);

    if ($validator->fails()) {
        return response()->json(responseFormatter(DEFAULT_400, errorProcessor($validator)), 403);
    }

    try {
        $date = \Carbon\Carbon::parse($request->day)->toDateString();

        $query = CarpoolRoute::with(['user.vehicle.model.brand', 'user.vehicle.category', 'trip'])
            ->whereDate('start_time', $date);

            // Apply filters
            if ($request->filled('ride_type')) {
                $query->where('ride_type', $request->ride_type);
            }

            if ($request->filled('gender')) {
                $query->where('allowed_gender', $request->gender);
            }

            if ($request->filled('seats_required')) {
                $query->where('seats_available', '>=', $request->seats_required);
            }
        $routes = $query->get();
        \Log::info('Matching ride routes retrieved', ['count' => $routes->count(), 'day' => $date,'route'=>$routes]);

        $results = [];

        foreach ($routes as $route) {
            $points = json_decode($route->route_points, true) ?? [];

            if (!empty($route->rest_stops)) {
                $restStops = json_decode($route->rest_stops, true) ?? [];
                foreach ($restStops as $stop) {
                    if (isset($stop['lat'], $stop['lng'])) {
                        $points[] = ['lat' => $stop['lat'], 'lng' => $stop['lng']];
                    }
                }
            }

           $pickupMatch = $this->isCloseToRoute($points, $request->pickup_lat, $request->pickup_lng, 0.4);
$dropoffMatch = $this->isCloseToRoute($points, $request->dropoff_lat, $request->dropoff_lng, 0.4);
            if (!$pickupMatch || !$dropoffMatch) {
                continue;
            }

            $vehicle = $route->user->vehicle;
            $categoryId = optional($vehicle->category)->id ?? 'uncategorized';

            if ($request->filled('category') && strtolower($request->category) !== 'all'
                && strtolower($request->category) !== strtolower(optional($vehicle->category)->name)) {
                continue;
            }

            $pickupPoint = $this->getClosestPoint($points, $request->pickup_lat, $request->pickup_lng);
            $dropoffPoint = $this->getClosestPoint($points, $request->dropoff_lat, $request->dropoff_lng);

            $startCoords = $route->start_location->getCoordinates();
            $endCoords = $route->end_location->getCoordinates();
            $routeDistance = $this->getDistanceInKm($startCoords[1], $startCoords[0], $endCoords[1], $endCoords[0]);

            $pricePerKm = $routeDistance > 0 ? $route->price / $routeDistance : 0;
            $tripDistance = $this->getDistanceInKm(
               $request->pickup_lat, $request->pickup_lng,
               $request->dropoff_lat, $request->dropoff_lng
            );
           $tripFare=round($tripDistance * $pricePerKm);
            $results[] = [
                'route_id' => $route->id,
                'driver' => optional($route->user)?->only(['id', 'full_name', 'gender', 'profile_image']),
                'vehicle' => [
                    'id' => $vehicle->id ?? null,
                    'category_id' => $categoryId,
                    'brand' => optional($vehicle->model->brand)->name ?? null,
                    'model' => optional($vehicle->model)->name ?? null,
                    'plate_number' => $vehicle->plate_number ?? null,
                ],
                'start_time' => $route->start_time->toDateTimeString(),
                'seats_available' => $route->seats_available,
                'is_ac' => $route->is_ac,
                'is_smoking_allowed' => $route->is_smoking_allowed,
                'pickup_match_point' => $pickupPoint,
                'dropoff_match_point' => $dropoffPoint,
                'pickup_address' => $this->getAddressFromLatLng($pickupPoint['lat'], $pickupPoint['lng']),
                'dropoff_address' => $this->getAddressFromLatLng($dropoffPoint['lat'], $dropoffPoint['lng']),
                'price' => $tripFare,
                'has_music' => $route->has_music,
                'has_screen_entertainment' => $route->has_screen_entertainment,
                'allow_luggage' => $route->allow_luggage,
                'allowed_gender' => $route->allowed_gender,
                'allowed_age_min' => $route->allowed_age_min,
                'allowed_age_max' => $route->allowed_age_max,
            ];
        }

        return response()->json(responseFormatter(DEFAULT_200, $results));
    } catch (\Throwable $e) {
        \Log::error('Error in findMatchingRides: ' . $e->getMessage(), [
            'trace' => $e->getTraceAsString(),
            'request_data' => $request->all()
        ]);
        return response()->json(['success'=>false , "message"=>"internal server error "], 500);
    }
}


 private function getDistanceInKm(float $startLat, float $startLng, float $endLat, float $endLng): float
{
    $cacheKey = "distance_{$startLat}_{$startLng}_{$endLat}_{$endLng}";
    $distance = cache()->get($cacheKey);
    if ($distance !== null) {
        return $distance;
    }
    $apiKey = env('GOOGLE_MAPS_API_KEY');
    $response = Http::get("https://maps.googleapis.com/maps/api/directions/json", [
        'origin' => "$startLat,$startLng",
        'destination' => "$endLat,$endLng",
        'mode' => 'driving',
        'key' => $apiKey,
    ]);

    if (!$response->ok() || $response['status'] !== 'OK') {
        return 0;
    }
    $distance = round($response['routes'][0]['legs'][0]['distance']['value'] / 1000, 2);
    cache()->put($cacheKey, $distance, now()->addHour());
    return $distance ; // convert to km
}

  private function getAddressFromLatLng(float $lat, float $lng): ?string
{
    $cacheKey = "address_{$lat}_{$lng}";
    $address = cache()->get($cacheKey);

    if ($address) {
        return $address;
    }

    $apiKey = env('GOOGLE_MAPS_API_KEY');
    $response = Http::get("https://maps.googleapis.com/maps/api/geocode/json", [
        'latlng' => "$lat,$lng",
        'key' => $apiKey,
        'language' => 'ar'
    ]);

    if (!$response->ok() || $response['status'] !== 'OK') {
        return null;
    }

    $address = $response['results'][0]['formatted_address'] ?? null;

    if ($address) {
        cache()->put($cacheKey, $address, now()->addHour());
    }

    return $address;
}


      private function haversineDistance(float $lat1, float $lon1, float $lat2, float $lon2): float
            {
                $earthRadius = 6371; // km
                $lat1 = deg2rad($lat1);
                $lon1 = deg2rad($lon1);
                $lat2 = deg2rad($lat2);
                $lon2 = deg2rad($lon2);

                $dlat = $lat2 - $lat1;
                $dlon = $lon2 - $lon1;

                $a = sin($dlat / 2) ** 2 + cos($lat1) * cos($lat2) * sin($dlon / 2) ** 2;
                $c = 2 * asin(sqrt($a));

                return $earthRadius * $c;
            }
    private function isCloseToRoute(array $routePoints, float $lat, float $lng, float $maxDistanceKm): bool
        {
            foreach ($routePoints as $point) {
                $distance = $this->haversineDistance($lat, $lng, $point['lat'], $point['lng']);
                if ($distance <= $maxDistanceKm) {
                    return true;
                }
            }
            return false;
        }

    private function getClosestPoint(array $routePoints, float $lat, float $lng): array
    {
        $minDistance = INF;
        $closest = null;

        foreach ($routePoints as $point) {
            $distance = $this->haversineDistance($lat, $lng, $point['lat'], $point['lng']);
            if ($distance < $minDistance) {
                $minDistance = $distance;
                $closest = $point;
            }
        }

        return $closest ?? ['lat' => $lat, 'lng' => $lng];
    }


public function getDriverRouteBeforeStart(Request $request): JsonResponse
{

    $validator = Validator::make($request->all(), [
        'car_pool_route_id' => 'required|exists:carpool_routes,id',
        'current_lat' => 'required|numeric',
        'current_lng' => 'required|numeric',
    ]);
    if ($validator->fails()) {
        return response()->json(responseFormatter(DEFAULT_400, errorProcessor($validator)), 403);
    }
    $carpoolRoute = CarpoolRoute::find($request->car_pool_route_id)->with(['user.lastLocations','user.vehicle.model','user.vehicle'])->first();
    $route=getRoutes(
        originCoordinates: [
          $carpoolRoute->user->lastLocations->latitude,
         $carpoolRoute->user->lastLocations->longitude,

        ],
        destinationCoordinates: [
            $request->pickup_lat,
            $request->pickup_lng
        ]);
    if (!$route) {
        $route=null;
    }

    $return=[
        'route_id' => $carpoolRoute->id,
        'start_time' => $carpoolRoute->start_time->format('Y-m-d H:i:s'),
        'start_address' => $this->getAddressFromLatLng($carpoolRoute->start_location->latitude, $carpoolRoute->start_location->longitude),
        'driver_name'=> $carpoolRoute->user->full_name,
        'driver_image' => $carpoolRoute->user->profile_image ? asset('storage/' . $carpoolRoute->user->profile_image) : null,
        'vehicle' => [
        'brand' => $carpoolRoute->user->vehicle->model->brand->name ?? 'غير معروف',
        'model' => $carpoolRoute->user->vehicle->model
            ? $carpoolRoute->user->vehicle->model->name : 'غير معروف',
        'category' => $carpoolRoute->user->vehicle->model->vehicleCategory  ],
        'polyline' => $route['polyline'] ?? null,
        'pickup_location' => [
            'latitude' => $request->pickup_lat,
            'longitude' => $request->pickup_lng
        ],
    ];
    return response()->json(responseFormatter(DEFAULT_200, [
        'data' => $return,
    ]));


}
public function createCarpoolRequest(Request $request)
{
    $validator = Validator::make($request->all(), [
        'carpool_route_id' => 'required|exists:carpool_routes,id',
        'pickup_coordinates' => 'required',
        'destination_coordinates' => 'required',
        'price' => 'sometimes|numeric|min:0',
        'min_fare' => 'required|numeric|min:0',
    ]);

    if ($validator->fails()) {
        return response()->json(responseFormatter(DEFAULT_400, errorProcessor($validator)), 403);
    }

    $trip = $this->tripRequest->getCustomerIncompleteRide();
    if ($trip) {
        return response()->json(responseFormatter(INCOMPLETE_RIDE_403), 403);
    }

    if (empty($request->header('zoneId'))) {
        return response()->json(responseFormatter(ZONE_404), 403);
    }


    $takenSeates=$this->tripRequest->getBy(criteria:["carpool_route_id"=>$request->carpool_route_id , "status"=>ACCEPTED])->count();

    $route = CarpoolRoute::where('id', $request->carpool_route_id)
            ->with(['user', 'vehicle'])
            ->first();

    if (!$route || !$route->vehicle) {
        return response()->json(responseFormatter(DEFAULT_404), 404);
    }

    if($route->seats_available <= $takenSeates) {
        return response()->json(responseFormatter(DEFAULT_400, ['message' => 'No seats available for this route']), 403);
    }


    try {
        $pickupCoordinates = json_decode($request['pickup_coordinates'], true, 512, JSON_THROW_ON_ERROR);
        $destinationCoordinates = json_decode($request['destination_coordinates'], true, 512, JSON_THROW_ON_ERROR);

        if (!is_array($pickupCoordinates) || count($pickupCoordinates) < 2 ||
            !is_array($destinationCoordinates) || count($destinationCoordinates) < 2) {
            throw new \InvalidArgumentException('Invalid coordinates format');
        }
    } catch (\Exception $e) {
        return response()->json(responseFormatter(DEFAULT_400, ['message' => 'Invalid coordinates format']), 400);
    }

    $pickupLat = (float)$pickupCoordinates[0];
    $pickupLng = (float)$pickupCoordinates[1];
    $destinationLat = (float)$destinationCoordinates[0];
    $destinationLng = (float)$destinationCoordinates[1];
    $pickupAddress = $this->getAddressFromLatLng($pickupLat, $pickupLng);
    $distinationAddress = $this->getAddressFromLatLng($destinationLat, $destinationLng);

    $polyline = getRoutes(
        originCoordinates: [$pickupLat, $pickupLng],
        destinationCoordinates: [$destinationLat, $destinationLng]
    );
      $ETA = Carbon::parse(now())->addMinutes(
                $this->getEstimatedDurationInMinutes($request->start_lat, $request->start_lng, $request->end_lat, $request->end_lng)
            );
    \Log::info("ployLine",["polyLine"=>$polyline]);

    $pickupPoint = new Point($pickupLat, $pickupLng);
    $destinationPoint = new Point($destinationLat, $destinationLng);
    $env = env('APP_MODE');
    $otp = $env != "live" ? '0000' : rand(1000, 9999);
    $request->merge([
        'pickup_coordinates' => $pickupPoint,
        'destination_coordinates' => $destinationPoint,
        'carpool_route_id' => $request->carpool_route_id,
        'customer_id' => auth('api')->id(),
        'zone_id' => $request->header('zoneId'),
        'actual_fare' => max($request->price ?? 0, $request->min_fare),
        'estimated_fare'=>max($request->price ?? 0, $request->min_fare),
        'otp'=>$otp,
        'current_status' => ACCEPTED,
        'encoded_polyline' => $polyline['polyline'] ?? null,
        'type'=> 'carpool',
        'estimated_time' => $ETA??0, // Assuming no ETA calculation needed
        'pickup_address' => $pickupAddress,
        'destination_address' => $distinationAddress,
        'driver_id' => $route->user_id,
        'vehicle_id' => $route->vehicle_id,
        'vechicle_category_id' => $route->vehicle->category_id,
        'estimated_distance' => $this->getDistanceInKm(
            $pickupLat,
            $pickupLng,
            $destinationLat,
            $destinationLng
        ),
        'customer_request_coordinates' => $pickupPoint,
    ]);

    $trip = $this->tripRequest->makeRideRequest($request, [$pickupLat, $pickupLng]);

    return response()->json(responseFormatter(DEFAULT_STORE_200, [
        'trip_id' => $trip->id,
    ]));


}

 private function getEstimatedDurationInMinutes(float $startLat, float $startLng, float $endLat, float $endLng): int
        {
            $apiKey = env('GOOGLE_MAPS_API_KEY');
            $response = Http::get("https://maps.googleapis.com/maps/api/directions/json", [
                'origin' => "$startLat,$startLng",
                'destination' => "$endLat,$endLng",
                'mode' => 'driving',
                'key' => $apiKey,
            ]);

            if (!$response->ok() || $response['status'] !== 'OK') {
                return 0;
            }

            return intval($response['routes'][0]['legs'][0]['duration']['value'] / 60); // in minutes
        }

}
