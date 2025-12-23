Geocoder
========

**Complete geocoding solution for Ruby.**

[![Gem Version](https://badge.fury.io/rb/geocoder.svg)](http://badge.fury.io/rb/geocoder)
[![Code Climate](https://codeclimate.com/github/alexreisner/geocoder/badges/gpa.svg)](https://codeclimate.com/github/alexreisner/geocoder)
[![Build Status](https://travis-ci.com/alexreisner/geocoder.svg?branch=master)](https://travis-ci.com/alexreisner/geocoder)

Key features:

* Forward and reverse geocoding.
* IP address geocoding.
* Connects to more than 40 APIs worldwide.
* Performance-enhancing features like caching.
* Integrates with ActiveRecord and Mongoid.
* Basic geospatial queries: search within radius (or rectangle, or ring).

Compatibility:

* Ruby versions: 2.1+, and JRuby.
* Databases: MySQL, PostgreSQL, SQLite, and MongoDB.
* Rails: 5.x, 6.x, and 7.x.
* Works outside of Rails with the `json` (for MRI) or `json_pure` (for JRuby) gem.


Table of Contents
-----------------

Basic Features:

* [Basic Search](#basic-search)
* [Geocoding Objects](#geocoding-objects)
* [Geospatial Database Queries](#geospatial-database-queries)
* [Geocoding HTTP Requests](#geocoding-http-requests)
* [Geocoding Service ("Lookup") Configuration](#geocoding-service-lookup-configuration)

Advanced Features:

* [Performance and Optimization](#performance-and-optimization)
* [Advanced Model Configuration](#advanced-model-configuration)
* [Advanced Database Queries](#advanced-database-queries)
* [Geospatial Calculations](#geospatial-calculations)
* [Batch Geocoding](#batch-geocoding)
* [Testing](#testing)
* [Error Handling](#error-handling)
* [Command Line Interface](#command-line-interface)

The Rest:

* [Technical Discussions](#technical-discussions)
* [Troubleshooting](#troubleshooting)
* [Known Issues](#known-issues)
* [Reporting Issues](https://github.com/alexreisner/geocoder/blob/master/CONTRIBUTING.md#reporting-bugs)
* [Contributing](https://github.com/alexreisner/geocoder/blob/master/CONTRIBUTING.md#making-changes)

See Also:

* [Guide to Geocoding APIs](https://github.com/alexreisner/geocoder/blob/master/README_API_GUIDE.md) (formerly part of this README)


Basic Search
------------

In its simplest form, Geocoder takes an address and searches for its latitude/longitude coordinates:

```ruby
results = Geocoder.search("Paris")
results.first.coordinates
# => [48.856614, 2.3522219]  # latitude and longitude
```

The reverse is possible too. Given coordinates, it finds an address:

```ruby
results = Geocoder.search([48.856614, 2.3522219])
results.first.address
# => "Hôtel de Ville, 75004 Paris, France"
```

You can also look up the location of an IP address:

```ruby
results = Geocoder.search("172.56.21.89")
results.first.coordinates
# => [30.267153, -97.7430608]
results.first.country
# => "United States"
```

**The success and accuracy of geocoding depends entirely on the API being used to do these lookups.** Most queries work fairly well with the default configuration, but every application has different needs and every API has its particular strengths and weaknesses. If you need better coverage for your application you'll want to get familiar with the large number of supported APIs, listed in the [API Guide](https://github.com/alexreisner/geocoder/blob/master/README_API_GUIDE.md).


Geocoding Objects
-----------------

To automatically geocode your objects:

**1.** Your model must provide a method that returns an address to geocode. This can be a single attribute, but it can also be a method that returns a string assembled from different attributes (eg: `city`, `state`, and `country`). For example, if your model has `street`, `city`, `state`, and `country` attributes you might do something like this:

```ruby
def address
  [street, city, state, country].compact.join(', ')
end
```

**2.** Your model must have a way to store latitude/longitude coordinates. With ActiveRecord, add two attributes/columns (of type float or decimal) called `latitude` and `longitude`. For MongoDB, use a single field (of type Array) called `coordinates` (i.e., `field :coordinates, type: Array`). (See [Advanced Model Configuration](#advanced-model-configuration) for using different attribute names.)

**3.** In your model, tell geocoder where to find the object's address:

```ruby
geocoded_by :address
```

This adds a `geocode` method which you can invoke via callback:

```ruby
after_validation :geocode
```

Reverse geocoding (given lat/lon coordinates, find an address) is similar:

```ruby
reverse_geocoded_by :latitude, :longitude
after_validation :reverse_geocode
```

With any geocoded objects, you can do the following:

```ruby
obj.distance_to([43.9,-98.6])  # distance from obj to point
obj.bearing_to([43.9,-98.6])   # bearing from obj to point
obj.bearing_from(obj2)         # bearing from obj2 to obj
```

The `bearing_from/to` methods take a single argument which can be: a `[lat,lon]` array, a geocoded object, or a geocodable address (string). The `distance_from/to` methods also take a units argument (`:mi`, `:km`, or `:nm` for nautical miles). See [Distance and Bearing](#distance-and-bearing) below for more info.

### One More Thing for MongoDB!

Before you can call `geocoded_by` you'll need to include the necessary module using one of the following:

```ruby
include Geocoder::Model::Mongoid
include Geocoder::Model::MongoMapper
```

### Latitude/Longitude Order in MongoDB

Everywhere coordinates are passed to methods as two-element arrays, Geocoder expects them to be in the order: `[lat, lon]`. However, as per [the GeoJSON spec](http://geojson.org/geojson-spec.html#positions), MongoDB requires that coordinates be stored longitude-first (`[lon, lat]`), so internally they are stored "backwards." Geocoder's methods attempt to hide this, so calling `obj.to_coordinates` (a method added to the object by Geocoder via `geocoded_by`) returns coordinates in the conventional order:

```ruby
obj.to_coordinates  # => [37.7941013, -122.3951096] # [lat, lon]
```

whereas calling the object's coordinates attribute directly (`obj.coordinates` by default) returns the internal representation which is probably the reverse of what you want:

```ruby
obj.coordinates     # => [-122.3951096, 37.7941013] # [lon, lat]
```

So, be careful.

### Use Outside of Rails

To use Geocoder with ActiveRecord and a framework other than Rails (like Sinatra or Padrino), you will need to add this in your model before calling Geocoder methods:

```ruby
extend Geocoder::Model::ActiveRecord
```


Geospatial Database Queries
---------------------------

### For ActiveRecord models:

To find objects by location, use the following scopes:

```ruby
Venue.near('Omaha, NE, US')                   # venues within 20 miles of Omaha
Venue.near([40.71, -100.23], 50)              # venues within 50 miles of a point
Venue.near([40.71, -100.23], 50, units: :km)  # venues within 50 kilometres of a point
Venue.geocoded                                # venues with coordinates
Venue.not_geocoded                            # venues without coordinates
```

With geocoded objects you can do things like this:

```ruby
if obj.geocoded?
  obj.nearbys(30)                       # other objects within 30 miles
  obj.distance_from([40.714,-100.234])  # distance from arbitrary point to object
  obj.bearing_to("Paris, France")       # direction from object to arbitrary point
end
```

### For MongoDB-backed models:

Please do not use Geocoder's `near` method. Instead use MongoDB's built-in [geospatial query language](https://docs.mongodb.org/manual/reference/command/geoNear/), which is faster. Mongoid also provides [a DSL](http://mongoid.github.io/en/mongoid/docs/querying.html#geo_near) for geospatial queries.


Geocoding HTTP Requests
-----------------------

Geocoder adds `location` and `safe_location` methods to the standard `Rack::Request` object so you can easily look up the location of any HTTP request by IP address. For example, in a Rails controller or a Sinatra app:

```ruby
# returns Geocoder::Result object
result = request.location
```

**The `location` method is vulnerable to trivial IP address spoofing via HTTP headers.**  If that's a problem for your application, use `safe_location` instead, but be aware that `safe_location` will *not* try to trace a request's originating IP through proxy headers; you will instead get the location of the last proxy the request passed through, if any (excepting any proxies you have explicitly whitelisted in your Rack config).

Note that these methods will usually return `nil` in test and development environments because things like "localhost" and "0.0.0.0" are not geocodable IP addresses.


Geocoding Service ("Lookup") Configuration
------------------------------------------

Geocoder supports a variety of street and IP address geocoding services. The default lookups are `:nominatim` for street addresses and `:ipinfo_io` for IP addresses. Please see the [API Guide](https://github.com/alexreisner/geocoder/blob/master/README_API_GUIDE.md) for details on specific geocoding services (not all settings are supported by all services).

To create a Rails initializer with sample configuration:

```sh
rails generate geocoder:config
```

Some common options are:

```ruby
# config/initializers/geocoder.rb
Geocoder.configure(
  # street address geocoding service (default :nominatim)
  lookup: :yandex,

  # IP address geocoding service (default :ipinfo_io)
  ip_lookup: :maxmind,

  # to use an API key:
  api_key: "...",

  # geocoding service request timeout, in seconds (default 3):
  timeout: 5,

  # set default units to kilometers:
  units: :km,

  # caching (see Caching section below for details):
  cache: Redis.new,
  cache_options: {
    expiration: 1.day, # Defaults to `nil`
    prefix: "another_key:" # Defaults to `geocoder:`
  }
)
```

Please see [`lib/geocoder/configuration.rb`](https://github.com/alexreisner/geocoder/blob/master/lib/geocoder/configuration.rb) for a complete list of configuration options. Additionally, some lookups have their own special configuration options which are directly supported by Geocoder. For example, to specify a value for Google's `bounds` parameter:

```ruby
# with Google:
Geocoder.search("Middletown", bounds: [[40.6,-77.9], [39.9,-75.9]])
```

Please see the [source code for each lookup](https://github.com/alexreisner/geocoder/tree/master/lib/geocoder/lookups) to learn about directly supported parameters. Parameters which are not directly supported can be specified using the `:params` option, which appends options to the query string of the geocoding request. For example:

```ruby
# Nominatim's `countrycodes` parameter:
Geocoder.search("Rome", params: {countrycodes: "us,ca"})

# Google's `region` parameter:
Geocoder.search("Rome", params: {region: "..."})
```

### Configuring Multiple Services

You can configure multiple geocoding services at once by using the service's name as a key for a sub-configuration hash, like this:

```ruby
Geocoder.configure(

  timeout: 2,
  cache: Redis.new,

  yandex: {
    api_key: "...",
    timeout: 5
  },

  baidu: {
    api_key: "..."
  },

  maxmind: {
    api_key: "...",
    service: :omni
  }

)
```

Lookup-specific settings override global settings so, in this example, the timeout for all lookups is 2 seconds, except for Yandex which is 5.


Performance and Optimization
----------------------------

### Database Indices

In MySQL and Postgres, queries use a bounding box to limit the number of points over which a more precise distance calculation needs to be done. To take advantage of this optimisation, you need to add a composite index on latitude and longitude. In your Rails migration:

```ruby
add_index :table, [:latitude, :longitude]
```

In MongoDB, by default, the methods `geocoded_by` and `reverse_geocoded_by` create a geospatial index. You can avoid index creation with the `:skip_index option`, for example:

```ruby
include Geocoder::Model::Mongoid
geocoded_by :address, skip_index: true
```

### Avoiding Unnecessary API Requests

Geocoding only needs to be performed under certain conditions. To avoid unnecessary work (and quota usage) you will probably want to geocode an object only when:

* an address is present
* the address has been changed since last save (or it has never been saved)

The exact code will vary depending on the method you use for your geocodable string, but it would be something like this:

```ruby
after_validation :geocode, if: ->(obj){ obj.address.present? and obj.address_changed? }
```

### Caching

When relying on any external service, it's always a good idea to cache retrieved data. When implemented correctly, it improves your app's response time and stability. It's easy to cache geocoding results with Geocoder -- just configure a cache store:

```ruby
Geocoder.configure(cache: Redis.new)
```

This example uses Redis, but the cache store can be any object that supports these methods:

* `store#[](key)` or `#get` or `#read` - retrieves a value
* `store#[]=(key, value)` or `#set` or `#write` - stores a value
* `store#del(url)` - deletes a value
* `store#keys` - (Optional) Returns array of keys. Used if you wish to expire the entire cache (see below).

Even a plain Ruby hash will work, though it's not a great choice (cleared out when app is restarted, not shared between app instances, etc).

When using Rails use the Generic cache store as an adapter around `Rails.cache`:

```ruby
Geocoder.configure(cache: Geocoder::CacheStore::Generic.new(Rails.cache, {}))
```

You can also set a custom prefix to be used for cache keys:

```ruby
Geocoder.configure(cache_options: { prefix: "..." })
```

By default the prefix is `geocoder:`

If you need to expire cached content:

```ruby
Geocoder::Lookup.get(Geocoder.config[:lookup]).cache.expire(:all)  # expire cached results for current Lookup
Geocoder::Lookup.get(:nominatim).cache.expire("http://...")        # expire cached result for a specific URL
Geocoder::Lookup.get(:nominatim).cache.expire(:all)                # expire cached results for Google Lookup
# expire all cached results for all Lookups.
# Be aware that this methods spawns a new Lookup object for each Service
Geocoder::Lookup.all_services.each{|service| Geocoder::Lookup.get(service).cache.expire(:all)}
```

Do *not* include the prefix when passing a URL to be expired. Expiring `:all` will only expire keys with the configured prefix -- it will *not* expire every entry in your key/value store.

For an example of a cache store with URL expiry, please see examples/autoexpire_cache.rb

_Before you implement caching in your app please be sure that doing so does not violate the Terms of Service for your geocoding service._


Advanced Model Configuration
----------------------------

You are not stuck with the `latitude` and `longitude` database column names (with ActiveRecord) or the `coordinates` array (Mongo) for storing coordinates. For example:

```ruby
geocoded_by :address, latitude: :lat, longitude: :lon  # ActiveRecord
geocoded_by :address, coordinates: :coords             # MongoDB
```

For reverse geocoding, you can specify the attribute where the address will be stored. For example:

```ruby
reverse_geocoded_by :latitude, :longitude, address: :loc    # ActiveRecord
reverse_geocoded_by :coordinates, address: :street_address  # MongoDB
```

To specify geocoding parameters in your model:

```ruby
geocoded_by :address, params: {region: "..."}
```

Supported parameters: `:lookup`, `:ip_lookup`, `:language`, and `:params`. You can specify an anonymous function if you want to set these on a per-request basis. For example, to use different lookups for objects in different regions:

```ruby
geocoded_by :address, lookup: lambda{ |obj| obj.geocoder_lookup }

def geocoder_lookup
  if country_code == "RU"
    :yandex
  elsif country_code == "CN"
    :baidu
  else
    :nominatim
  end
end
```

### Custom Result Handling

So far we have seen examples where geocoding results are assigned automatically to predefined object attributes. However, you can skip the auto-assignment by providing a block which handles the parsed geocoding results any way you like, for example:

```ruby
reverse_geocoded_by :latitude, :longitude do |obj,results|
  if geo = results.first
    obj.city    = geo.city
    obj.zipcode = geo.postal_code
    obj.country = geo.country_code
  end
end

after_validation :reverse_geocode
```

Every `Geocoder::Result` object, `result`, provides the following data:

* `result.latitude` - float
* `result.longitude` - float
* `result.coordinates` - array of the above two in the form of `[lat,lon]`
* `result.address` - string
* `result.city` - string
* `result.state` - string
* `result.state_code` - string
* `result.postal_code` - string
* `result.country` - string
* `result.country_code` - string

Most APIs return other data in addition to these globally-supported attributes. To directly access the full response, call the `#data` method of any Geocoder::Result object. See the [API Guide](https://github.com/alexreisner/geocoder/blob/master/README_API_GUIDE.md) for links to documentation for all geocoding services.

### Forward and Reverse Geocoding in the Same Model

You can apply both forward and reverse geocoding to the same model (i.e. users can supply an address or coordinates and Geocoder fills in whatever's missing) but you'll need to provide two different address methods:

* one for storing the fetched address (when reverse geocoding)
* one for providing an address to use when fetching coordinates (forward geocoding)

For example:

```ruby
class Venue
  # build an address from street, city, and state attributes
  geocoded_by :address_from_components

  # store the fetched address in the full_address attribute
  reverse_geocoded_by :latitude, :longitude, address: :full_address
end
```

The same goes for latitude/longitude. However, for purposes of querying the database, there can be only one authoritative set of latitude/longitude attributes for use in database queries. This is whichever you specify last. For example, here the attributes *without* the `fetched_` prefix will be authoritative:

```ruby
class Venue
  geocoded_by :address,
    latitude: :fetched_latitude,
    longitude: :fetched_longitude
  reverse_geocoded_by :latitude, :longitude
end
```


Advanced Database Queries
-------------------------

*The following apply to ActiveRecord only. For MongoDB, please use the built-in geospatial features.*

The default `near` search looks for objects within a circle. To search within a doughnut or ring use the `:min_radius` option:

```ruby
Venue.near("Austin, TX", 200, min_radius: 40)
```

To search within a rectangle (note that results will *not* include `distance` and `bearing` attributes):

```ruby
sw_corner = [40.71, 100.23]
ne_corner = [36.12, 88.65]
Venue.within_bounding_box(sw_corner, ne_corner)
```

To search for objects near a certain point where each object has a different distance requirement (which is defined in the database), you can pass a column name for the radius:

```ruby
Venue.near([40.71, 99.23], :effective_radius)
```

If you store multiple sets of coordinates for each object, you can specify latitude and longitude columns to use for a search:

```ruby
Venue.near("Paris", 50, latitude: :secondary_latitude, longitude: :secondary_longitude)
```

### Distance and Bearing

When you run a geospatial query, the returned objects have two attributes added:

* `obj.distance` - number of miles from the search point to this object
* `obj.bearing` - direction from the search point to this object

Results are automatically sorted by distance from the search point, closest to farthest. Bearing is given as a number of degrees clockwise from due north, for example:

* `0` - due north
* `180` - due south
* `90` - due east
* `270` - due west
* `230.1` - southwest
* `359.9` - almost due north

You can convert these to compass point names via provided method:

```ruby
Geocoder::Calculations.compass_point(355) # => "N"
Geocoder::Calculations.compass_point(45)  # => "NE"
Geocoder::Calculations.compass_point(208) # => "SW"
```

_Note: when running queries on SQLite, `distance` and `bearing` are provided for consistency only. They are not very accurate._

For more advanced geospatial querying, please see the [rgeo gem](https://github.com/rgeo/rgeo).


Geospatial Calculations
-----------------------

The `Geocoder::Calculations` module contains some useful methods:

```ruby
# find the distance between two arbitrary points
Geocoder::Calculations.distance_between([47.858205,2.294359], [40.748433,-73.985655])
 => 3619.77359999382 # in configured units (default miles)

# find the geographic center (aka center of gravity) of objects or points
Geocoder::Calculations.geographic_center([city1, city2, [40.22,-73.99], city4])
 => [35.14968, -90.048929]
```

See [the code](https://github.com/alexreisner/geocoder/blob/master/lib/geocoder/calculations.rb) for more!


Batch Geocoding
---------------

If you have just added geocoding to an existing application with a lot of objects, you can use this Rake task to geocode them all:

```sh
rake geocode:all CLASS=YourModel
```

If you need reverse geocoding instead, call the task with REVERSE=true:

```sh
rake geocode:all CLASS=YourModel REVERSE=true
```

In either case, it won't try to geocode objects that are already geocoded. The task will print warnings if you exceed the rate limit for your geocoding service. Some services enforce a per-second limit in addition to a per-day limit. To avoid exceeding the per-second limit, you can add a `SLEEP` option to pause between requests for a given amount of time. You can also load objects in batches to save memory, for example:

```sh
rake geocode:all CLASS=YourModel SLEEP=0.25 BATCH=100
```

To avoid exceeding per-day limits you can add a `LIMIT` option. However, this will ignore the `BATCH` value, if provided.

```sh
rake geocode:all CLASS=YourModel LIMIT=1000
```


Testing
-------

When writing tests for an app that uses Geocoder it may be useful to avoid network calls and have Geocoder return consistent, configurable results. To do this, configure the `:test` lookup and/or `:ip_lookup`

```ruby
Geocoder.configure(lookup: :test, ip_lookup: :test)
```

Add stubs to define the results that will be returned:

```ruby
Geocoder::Lookup::Test.add_stub(
  "New York, NY", [
    {
      'coordinates'  => [40.7143528, -74.0059731],
      'address'      => 'New York, NY, USA',
      'state'        => 'New York',
      'state_code'   => 'NY',
      'country'      => 'United States',
      'country_code' => 'US'
    }
  ]
)
```

With the above stub defined, any query for "New York, NY" will return the results array that follows. You can also set a default stub, to be returned when no other stub matches a given query:

```ruby
Geocoder::Lookup::Test.set_default_stub(
  [
    {
      'coordinates'  => [40.7143528, -74.0059731],
      'address'      => 'New York, NY, USA',
      'state'        => 'New York',
      'state_code'   => 'NY',
      'country'      => 'United States',
      'country_code' => 'US'
    }
  ]
)
```

You may also delete a single stub, or reset all stubs _including the default stub_:

```ruby
Geocoder::Lookup::Test.delete_stub('New York, NY')
Geocoder::Lookup::Test.reset
```

Notes:

- Keys must be strings (not symbols) when calling `add_stub` or `set_default_stub`. For example `'country' =>` not `:country =>`.
- The stubbed result objects returned by the Test lookup do not support all the methods real result objects do. If you need to test interaction with real results it may be better to use an external stubbing tool and something like WebMock or VCR to prevent network calls.


Error Handling
--------------

By default Geocoder will rescue any exceptions raised by calls to a geocoding service and return an empty array. You can override this on a per-exception basis, and also have Geocoder raise its own exceptions for certain events (eg: API quota exceeded) by using the `:always_raise` option:

```ruby
Geocoder.configure(always_raise: [SocketError, Timeout::Error])
```

You can also do this to raise all exceptions:

```ruby
Geocoder.configure(always_raise: :all)
```

The raise-able exceptions are:

```ruby
SocketError
Timeout::Error
Geocoder::OverQueryLimitError
Geocoder::RequestDenied
Geocoder::InvalidRequest
Geocoder::InvalidApiKey
Geocoder::ServiceUnavailable
```

Note that only a few of the above exceptions are raised by any given lookup, so there's no guarantee if you configure Geocoder to raise `ServiceUnavailable` that it will actually be raised under those conditions (because most APIs don't return 503 when they should; you may get a `Timeout::Error` instead). Please see the source code for your particular lookup for details.


Command Line Interface
----------------------

When you install the Geocoder gem it adds a `geocode` command to your shell. You can search for a street address, IP address, postal code, coordinates, etc just like you can with the Geocoder.search method for example:

```sh
$ geocode 29.951,-90.081
Latitude:         29.952211
Longitude:        -90.080563
Full address:     1500 Sugar Bowl Dr, New Orleans, LA 70112, USA
City:             New Orleans
State/province:   Louisiana
Postal code:      70112
Country:          United States
Map:              http://maps.google.com/maps?q=29.952211,-90.080563
```

There are also a number of options for setting the geocoding API, key, and language, viewing the raw JSON response, and more. Please run `geocode -h` for details.


Technical Discussions
---------------------

### Distance Queries in SQLite

SQLite's lack of trigonometric functions requires an alternate implementation of the `near` scope. When using SQLite, Geocoder will automatically use a less accurate algorithm for finding objects near a given point. Results of this algorithm should not be trusted too much as it will return objects that are outside the given radius, along with inaccurate distance and bearing calculations.

There are few options for finding objects near a given point in SQLite without installing extensions:

1. Use a square instead of a circle for finding nearby points. For example, if you want to find points near 40.71, 100.23, search for objects with latitude between 39.71 and 41.71 and longitude between 99.23 and 101.23. One degree of latitude or longitude is at most 69 miles so divide your radius (in miles) by 69.0 to get the amount to add and subtract from your center coordinates to get the upper and lower bounds. The results will not be very accurate (you'll get points outside the desired radius), but you will get all the points within the required radius.

2. Load all objects into memory and compute distances between them using the `Geocoder::Calculations.distance_between` method. This will produce accurate results but will be very slow (and use a lot of memory) if you have a lot of objects in your database.

3. If you have a large number of objects (so you can't use approach #2) and you need accurate results (better than approach #1 will give), you can use a combination of the two. Get all the objects within a square around your center point, and then eliminate the ones that are too far away using `Geocoder::Calculations.distance_between`.

Because Geocoder needs to provide this functionality as a scope, we must go with option #1, but feel free to implement #2 or #3 if you need more accuracy.

### Numeric Data Types and Precision

Geocoder works with any numeric data type (e.g. float, double, decimal) on which trig (and other mathematical) functions can be performed.

A summary of the relationship between geographic precision and the number of decimal places in latitude and longitude degree values is available on [Wikipedia](http://en.wikipedia.org/wiki/Decimal_degrees#Accuracy). As an example: at the equator, latitude/longitude values with 4 decimal places give about 11 metres precision, whereas 5 decimal places gives roughly 1 metre precision.


Troubleshooting
---------------

### Mongoid

If you get one of these errors:

```ruby
uninitialized constant Geocoder::Model::Mongoid
uninitialized constant Geocoder::Model::Mongoid::Mongo
```

you should check your Gemfile to make sure the Mongoid gem is listed _before_ Geocoder. If Mongoid isn't loaded when Geocoder is initialized, Geocoder will not load support for Mongoid.

### ActiveRecord

A lot of debugging time can be saved by understanding how Geocoder works with ActiveRecord. When you use the `near` scope or the `nearbys` method of a geocoded object, Geocoder creates an ActiveModel::Relation object which adds some attributes (eg: distance, bearing) to the SELECT clause. It also adds a condition to the WHERE clause to check that distance is within the given radius. Because the SELECT clause is modified, anything else that modifies the SELECT clause may produce strange results, for example:

* using the `pluck` method (selects only a single column)
* specifying another model through `includes` (selects columns from other tables)

### Geocoding is Slow

With most lookups, addresses are translated into coordinates via an API that must be accessed through the Internet. These requests are subject to the same bandwidth constraints as every other HTTP request, and will vary in speed depending on network conditions. Furthermore, many of the services supported by Geocoder are free and thus very popular. Often they cannot keep up with demand and their response times become quite bad.

If your application requires quick geocoding responses you will probably need to pay for a non-free service, or--if you're doing IP address geocoding--use a lookup that doesn't require an external (network-accessed) service.

For IP address lookups in Rails applications, it is generally NOT a good idea to run `request.location` during a synchronous page load without understanding the speed/behavior of your configured lookup. If the lookup becomes slow, so will your website.

For the most part, the speed of geocoding requests has little to do with the Geocoder gem. Please take the time to learn about your configured lookup before posting performance-related issues.

### Unexpected Responses from Geocoding Services

Take a look at the server's raw response. You can do this by getting the request URL in an app console:

```ruby
Geocoder::Lookup.get(:nominatim).query_url(Geocoder::Query.new("..."))
```

Replace `:nominatim` with the lookup you are using and replace `...` with the address you are trying to geocode. Then visit the returned URL in your web browser. Often the API will return an error message that helps you resolve the problem. If, after reading the raw response, you believe there is a problem with Geocoder, please post an issue and include both the URL and raw response body.

You can also fetch the response in the console:

```ruby
Geocoder::Lookup.get(:nominatim).send(:fetch_raw_data, Geocoder::Query.new("..."))
```


Known Issues
------------

### Using `count` with Rails 4.1+

Due to [a change in ActiveRecord's `count` method](https://github.com/rails/rails/pull/10710) you will need to use `count(:all)` to explicitly count all columns ("*") when using a `near` scope. Using `near` and calling `count` with no argument will cause exceptions in many cases.

### Using `near` with `includes`

You cannot use the `near` scope with another scope that provides an `includes` option because the `SELECT` clause generated by `near` will overwrite it (or vice versa).

Instead of using `includes` to reduce the number of database queries, try using `joins` with either the `:select` option or a call to `preload`. For example:

```ruby
# Pass a :select option to the near scope to get the columns you want.
# Instead of City.near(...).includes(:venues), try:
City.near("Omaha, NE", 20, select: "cities.*, venues.*").joins(:venues)

# This preload call will normally trigger two queries regardless of the
# number of results; one query on hotels, and one query on administrators.
# Instead of Hotel.near(...).includes(:administrator), try:
Hotel.near("London, UK", 50).joins(:administrator).preload(:administrator)
```

If anyone has a more elegant solution to this problem I am very interested in seeing it.

### Using `near` with objects close to the 180th meridian

The `near` method will not look across the 180th meridian to find objects close to a given point. In practice this is rarely an issue outside of New Zealand and certain surrounding islands. This problem does not exist with the zero-meridian. The problem is due to a shortcoming of the Haversine formula which Geocoder uses to calculate distances.


Copyright :copyright: 2009-2021 Alex Reisner, released under the MIT license.
