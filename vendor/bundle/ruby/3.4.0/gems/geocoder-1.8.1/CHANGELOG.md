Changelog
=========

Major changes to Geocoder for each release. Please see the Git log for complete list of changes.

1.8.1 (2022 Sep 23)
-------------------
* Add support for IPBase lookup (thanks github.com/jonallured).
* Test cleanup (thanks github.com/jonallured).
* Prevent errors when existing constant name shadows a lookup class (thanks github.com/avram-twitch).

1.8.0 (2022 May 17)
-------------------
* Add support for 2GIS lookup (thanks github.com/ggrikgg).
* Change cache configuration structure and add an expiration option. Cache prefix is now set via {cache_options: {prefix: ...}} instead of {cache_prefix: ...}. See README for details.
* Add `:fields` parameter for :google_places_details and :google_places_search lookups. If you haven't been requesting specific fields, you may start getting different data (defaults are now the APIs' defaults). See for details: https://github.com/alexreisner/geocoder/pull/1572 (thanks github.com/czlee).
* Update :here lookup to use API version 7. Query options are different, API key must be a string (not an array). See API docs at https://developer.here.com/documentation/geocoding-search-api/api-reference-swagger.html (thanks github.com/Pritilender).

1.7.5 (2022 Mar 14)
-------------------
* Avoid lookup naming collisions in some environments.

1.7.4 (2022 Mar 14)
-------------------
* Add ability to use app-defined lookups (thanks github.com/januszm).
* Updates to LocationIQ and FreeGeoIP lookups.

1.7.3 (2022 Jan 17)
-------------------
* Get rid of unnecessary cache_prefix deprecation warnings.

1.7.2 (2022 Jan  2)
-------------------
* Fix uninitialized constant error (occurring on some systems with v1.7.1).

1.7.1 (2022 Jan  1)
-------------------
* Various bugfixes and refactorings.

1.7.0 (2021 Oct 11)
-------------------
* Add support for Geoapify and Photo lookups (thanks github.com/ahukkanen).
* Add support for IPQualityScore IP lookup (thanks github.com/jamesbebbington).
* Add support for Amazon Location Service lookup (thanks github.com/mplewis).
* Add support for Melissa lookup (thanks github.com/ALacker).
* Drop official support for Ruby 2.0.x and Rails 4.x.

1.6.7 (2021 Apr 17)
-------------------
* Add support for Abstract API lookup (thanks github.com/randoum).

1.6.6 (2021 Mar  4)
-------------------
* Rescue from exception on cache read/write error. Issue warning instead.

1.6.5 (2021 Feb 10)
-------------------
* Fix backward coordinates bug in NationaalregisterNl lookup (thanks github.com/Marthyn).
* Allow removal of single stubs in test mode (thanks github.com/jmmastey).
* Improve results for :ban_data_gouv_fr lookup (thanks github.com/Intrepidd).

1.6.4 (2020 Oct  6)
-------------------
* Various updates in response to geocoding API changes.
* Refactor of Google Places Search lookup (thanks github.com/maximilientyc).

1.6.3 (2020 Apr 30)
-------------------
* Update URL for :telize lookup (thanks github.com/alexwalling).
* Fix bug parsing IPv6 with port (thanks github.com/gdomingu).

1.6.2 (2020 Mar 16)
-------------------
* Add support for :nationaal_georegister_nl lookup (thanks github.com/opensourceame).
* Add support for :uk_ordnance_survey_names lookup (thanks github.com/pezholio).
* Refactor and fix bugs in Yandex lookup (thanks github.com/iarie and stereodenis).

1.6.1 (2020 Jan 23)
-------------------
* Sanitize lat/lon values passed to within_bounding_box to prevent SQL injection.

1.6.0 (2020 Jan  6)
-------------------
* Drop support for Rails 3.x.
* Add support for :osmnames lookup (thanks github.com/zacviandier).
* Add support for :ipgeolocation IP lookup (thanks github.com/ahsannawaz111).

1.5.2 (2019 Oct  3)
-------------------
* Add support for :ipregistry lookup (thanks github.com/ipregistry).
* Various fixes for Yandex lookup.

1.5.1 (2019 Jan 23)
-------------------
* Add support for :tencent lookup (thanks github.com/Anders-E).
* Add support for :smarty_streets international API (thanks github.com/ankane).
* Remove :mapzen lookup.

1.5.0 (2018 Jul 31)
-------------------
* Drop support for Ruby <2.0.
* Change default street address lookup from :google to :nominatim.
* Cache keys no longer include API credentials. This means many entries in existing cache implementations will be invalidated.
* Test lookup fixtures should now return `coordinates` and NOT `latitude`/`longitude` attributes (see #1258). This may break some people's tests.
* Add support for :ip2location lookup (thanks github.com/ip2location).
* Remove :ovi and :okf lookups.

1.4.9 (2018 May 27)
-------------------
* Fix regression in :geoip2 lookup.
* Add support for Postcodes.io lookup (thanks github.com/sledge909).

1.4.8 (2018 May 21)
-------------------
* Change default IP address lookup from :freegeoip to :ipinfo_io.
* Add support for :ipstack lookup (thanks github.com/Heath101).
* Fix incompatibility with redis-rb gem v4.0.

1.4.7 (2018 Mar 13)
-------------------
* Allow HTTP protocol for Nominatim.

1.4.6 (2018 Feb 28)
-------------------
* Add support for :ipdata_co lookup (thanks github.com/roschaefer).
* Update for Rails 5.2 compatibility (thanks github.com/stevenharman).

1.4.5 (2017 Nov 29)
-------------------
* Add support for :pickpoint lookup (thanks github.com/cylon-v).
* Add support for :db_ip_com lookup (thanks github.com/cv).
* Change FreeGeoIP host to freegeoip.net.
* Allow search radius to be a symbol representing a column in DB (thanks github.com/leonelgalan).
* Add support for new parameters and improved error handling for several lookups.
* Fix bug in SQL when searching for objects across 180th meridian.

1.4.4 (2017 May 17)
-------------------
* Use HTTPS by default for :freegeoip (thanks github.com/mehanoid).
* Add support for :amap lookup (thanks github.com/pzgz).

1.4.3 (2017 Feb  7)
-------------------
* Add :google_places_search lookup (thanks github.com/waruboy).

1.4.2 (2017 Jan 31)
-------------------
* Fix bug that caused Model.near to return an incorrect query in some cases.

1.4.1 (2016 Dec  2)
-------------------
* Add :location_iq lookup (thanks github.com/aleemuddin13 and glsignal).
* Add :ban_data_gouv_fr lookup (thanks github.com/JulianNacci).
* Fix :mapbox results when server returns no context (thanks github.com/jcmuller).
* Deprecate methods in Geocoder::Calculations: to_kilometers, to_miles, to_nautical_miles, mi_in_km, km_in_mi, km_in_nm, nm_in_km.

1.4.0 (2016 Sep  8)
-------------------
* Only consider an object geocoded if both lat and lon are present (previously was sufficient to have only one of the two) (thanks github.com/mltsy).
* Add support in :geocodio lookup for Canadian addresses (thanks github.com/bolandrm).
* Add support for SQLite extensions, if present (thanks github.com/stevecj).
* Always include Geocoder in Rack::Request, if defined (thanks github.com/wjordan).

1.3.7 (2016 Jun  9)
-------------------
* Fix Ruby 1.9, 2.0 incompatibility (thanks github.com/ebouchut).
* Update SmartyStreets zipcode API endpoint (thanks github.com/jeffects).
* Catch network errors (thanks github.com/sas1ni69).

1.3.6 (2016 May 31)
-------------------
* Fix Sinatra support broken in 1.3.5.

1.3.5 (2016 May 27)
-------------------
* Fix Rails 5 ActionDispatch include issue (thanks github.com/alepore).
* Fix bug that caused :esri lookup to ignore certain configured parameters (thanks github.com/aaronpk).
* Add reverse geocoding support to :pelias/:mapzen (thanks github.com/shinyaK14).
* Add support for custom host with :telize (thanks github.com/jwaldrip).
* Change the way :esri lookup generates cache keys for improved performance (thanks github.com/aaronpk).
* Improve HTTPS connections with :google (thanks github.com/jlhonora).

1.3.4 (2016 Apr 14)
-------------------
* Update :freegeoip host (old one is down).
* Add IP lookup :ipapi_com (thanks github.com/piotrgorecki).

1.3.3 (2016 Apr 4)
------------------
* Fix incorrect gem version number.

1.3.2 (2016 Apr 1)
------------------
* Remove :yahoo lookup (service was discontinued Mar 31) (thanks github.com/galiat).
* Add support for LatLon.io service (thanks github.com/evanmarks).
* Add support for IpInfo.io service (thanks github.com/rehan, akostyuk).
* Add support for Pelias/Mapzen service (thanks github.com/RealScout).

1.3.1 (2016 Feb 20)
-------------------
* Warn about upcoming discontinuation of :yahoo lookup (thanks github.com/galiat).
* Add #viewport method to results that return viewport data (thanks github.com/lime).

1.3.0 (2016 Jan 31)
-------------------
* Lazy load lookups to reduce memory footprint (thanks github.com/TrangPham).
* Add :geoportail_lu lookup (Luxembourg only) (thanks github.com/mdebo).
* Maxmind local query performance improvement (thanks github.com/vojtad).
* Remove deprecated Mongo near query methods (please use Mongo-native methods instead).

1.2.14 (2015 Dec 27)
--------------------
* Fix bug in :geoip2 lookup (thanks github.com/mromulus).

1.2.13 (2015 Dec 15)
--------------------
* Update :telize IP lookup to reflect new URL (thanks github.com/jfredrickson).
* Add reverse geocode rake task (thanks github.com/FanaHOVA).
* Fix reversed coordinates array with Mapbox (thanks github.com/marcusat).
* Fix missing city name in some cases with ESRI (thanks github.com/roybotnik).
* Prevent re-opening of DB file on every read with :geoip2 (thanks github.com/oogali).

1.2.12 (2015 Oct 29)
--------------------
* Fix Ruby 1.9.3 incompatibility (remove non-existent timeout classes) (thanks github.com/roychri).

1.2.11 (2015 Sep 10)
--------------------
* Fix load issue on Ruby 1.9.3.

1.2.10 (2015 Sep 7)
-------------------
* Force Yandex to use HTTPS (thanks github.com/donbobka).
* Force :google to use HTTPS if API key set.
* Fix out-of-the-box verbosity issues (GH #881).
* Improve timeout mechanism and add exception Geocoder::LookupTimeout (thanks github.com/ankane).
* Deprecate .near and #nearbys for MongoDB-backed models.

1.2.9 (2015 Jun 12)
-------------------
* Don't cache unsuccessful responses from Bing (thanks github.com/peteb).
* Show API response when not valid JSON.
* Log each API request.
* Force all SmartyStreets requests to use HTTPS.

1.2.8 (2015 Mar 21)
-------------------
* Add :maxmind_geoip2 lookup (thanks github.com/TrangPham).
* Add ability to force/specify query type (street or IP address) (thanks github.com/TrangPham).
* Add :basic_auth configuration (thanks github.com/TrangPham).
* Add `safe_location` method for Rails controllers (thanks github.com/edslocomb).
* Add :logger configuration (thanks github.com/TrangPham).
* Improve error condition handling with Bing (thanks github.com/TrangPham).

1.2.7 (2015 Jan 24)
-------------------
* DROP SUPPORT for Ruby 1.9.2.
* Use UTF-8 encoding for maxmind_local results (thanks github.com/ellmo).
* Update freegeoip response handling (thanks github.com/hosamaly).
* Update nominatim response handling (thanks github.com/jsantos).
* Update yandex response handling (thanks github.com/wfleming).
* Update geocodio response handling (thanks github.com/getsidewalk).
* Add ability to raise exception when response parsing fails (thanks github.com/spiderpug).
* Fix double-loading of Railtie (thanks github.com/wfleming and zhouguangming).

1.2.6 (2014 Nov 8)
------------------
* Add :geoip2 lookup (thanks github.com/ChristianHoj).
* Add :okf lookup (thanks github.com/kakoni).
* Add :postcode_anywhere_uk lookup (thanks github.com/rob-murray).
* Properly detect IPv6 addresses (thanks github.com/sethherr and github.com/ignatiusreza).

1.2.5 (2014 Sep 12)
-------------------
* Fix bugs in :opencagedata lookup (thanks github.com/duboff and kayakyakr).
* Allow language to be set in model configuration (thanks github.com/viniciusnz).
* Optimize lookup queries when using MaxMind Local (thanks github.com/gersmann).

1.2.4 (2014 Aug 12)
-------------------
* Add ability to specify lat/lon column names with .near scope (thanks github.com/switzersc).
* Add OpenCageData geocoder (thanks github.com/mtmail).
* Remove CloudMade geocoder.

1.2.3 (2014 Jul 11)
-------------------
* Add Telize IP address lookup (thanks github.com/lukeroberts1990).
* Fix bug in Bing reverse geocoding (thanks github.com/nickelser).

1.2.2 (2014 Jun 12)
-------------------
* Add ability to specify language per query (thanks github.com/mkristian).
* Handle Errno::ECONNREFUSED exceptions like TimeoutError exceptions.
* Switch to 'unstructured' query format for Bing API (thanks github.com/lukewendling).

1.2.1 (2014 May 12)
-------------------

* Fix: correctly handle encoding of MaxMind API responses (thanks github.com/hydrozen, gonzoyumo).
* Fixes to :maxmind_local database structure (thanks github.com/krakatoa).

1.2.0 (2014 Apr 16)
-------------------

* DROP SUPPORT for Ruby 1.8.x.
* Add :here lookup (thanks github.com/christoph-buente).
* Add :cloudmade lookup (thanks github.com/spoptchev).
* Add :smarty_streets lookup (thanks github.com/drinks).
* Add :maxmind_local IP lookup (thanks github.com/fernandomm).
* Add :baidu_ip lookup (thanks github.com/yonggu).
* Add :geocodio lookup (thanks github.com/dblock).
* Add :lookup option to `Geocoder.search` and `geocoded_by` (thanks github.com/Bonias).
* Add support for :maxmind_local on JRuby via jgeoip gem (thanks github.com/gxbe).
* Add support for using :maxmind_local with an SQL database, including Rake tasks for downloading CSV data and populating a local DB.
* Add support for character encodings based on Content-type header (thanks github.com/timaro).
* Add :min_radius option to `near` scope (thanks github.com/phallstrom).
* Fix: Yandex city attribute caused exception with certain responses (thanks github.com/dblock).
* Change name of MapQuest config option from :licensed to :open and revert default behavior to be MapQuest data (not OpenStreetMaps).
* Reduce number of Ruby warnings (thanks github.com/exviva).

1.1.9 (2013 Dec 11)
-------------------

* DEPRECATED support for Ruby 1.8.x. Will be dropped in a future version.
* Require API key for MapQuest (thanks github.com/robdiciuccio).
* Add support for geocoder.us and HTTP basic auth (thanks github.com/komba).
* Add support for Data Science Toolkit lookup (thanks github.com/ejhayes).
* Add support for Baidu (thanks github.com/mclee).
* Add Geocoder::Calculations.random_point_near method (thanks github.com/adambray).
* Fix: #nearbys method with Mongoid (thanks github.com/pascalbetz).
* Fix: bug in FreeGeoIp lookup that was preventing exception from being raised when configured cache was unavailable.

1.1.8 (2013 Apr 22)
-------------------

* Fix bug in ESRI lookup that caused an exception on load in environments without rack/utils.

1.1.7 (2013 Apr 21)
-------------------

* Add support for Ovi/Nokia API (thanks github.com/datenimperator).
* Add support for ESRI API (thanks github.com/rpepato).
* Add ability to omit distance and bearing from SQL select clause (thanks github.com/nicolasdespres).
* Add support for caches that use read/write methods (thanks github.com/eskil).
* Add support for nautical miles (thanks github.com/vanboom).
* Fix: bug in parsing of MaxMind responses.
* Fix: bugs in query regular expressions (thanks github.com/boone).
* Fix: various bugs in MaxMind implementation.
* Fix: don't require a key for MapQuest.
* Fix: bug in handling of HTTP_X_FORWARDED_FOR header (thanks github.com/robdimarco).

1.1.6 (2012 Dec 24)
-------------------

* Major changes to configuration syntax which allow for API-specific config options. Old config syntax is now DEPRECATED.
* Add support for MaxMind API (thanks github.com/gonzoyumo).
* Add optional Geocoder::InvalidApiKey exception for bad API credentials (Yahoo, Yandex, Bing, and Maxmind). Warn when bad key and exception not set in Geocoder.configure(:always_raise => [...]).
* Add support for X-Real-IP and X-Forwarded-For headers (thanks github.com/konsti).
* Add support for custom Nominatim host config: Geocoder.configure(:nominatim => {:host => "..."}).
* Raise exception when required API key is missing or incorrect format.
* Add support for Google's :region and :components parameters (thanks to github.com/tomlion).
* Fix: string escaping bug in OAuth lib (thanks github.com/m0thman).
* Fix: configured units were not always respected in SQL queries.
* Fix: in #nearbys, don't try to exclude self if not yet persisted.
* Fix: bug with cache stores that provided #delete but not #del.
* Change #nearbys so that it returns nil instead of [] when object is not geocoded.

1.1.5 (2012 Nov 9)
------------------

* Replace support for old Yahoo Placefinder with Yahoo BOSS (thanks github.com/pwoltman).
* Add support for actual Mapquest API (was previously just a proxy for Nominatim), including the paid service (thanks github.com/jedschneider).
* Add support for :select => :id_only option to near scope.
* Treat a given query as blank (don't do a lookup) if coordinates are given but latitude or longitude is nil.
* Speed up 'near' queries by adding bounding box condition (thanks github.com/mlandauer).
* Fix: don't redefine Object#hash in Yahoo result object (thanks github.com/m0thman).

1.1.4 (2012 Oct 2)
------------------

* Deprecate Geocoder::Result::Nominatim#class and #type methods. Use #place_class and #place_type instead.
* Add support for setting arbitrary parameters in geocoding request URL.
* Add support for Google's :bounds parameter (thanks to github.com/rosscooperman and github.com/peterjm for submitting suggestions).
* Add support for :select => :geo_only option to near scope (thanks github.com/gugl).
* Add ability to omit ORDER BY clause from .near scope (pass option :order => false).
* Fix: error on Yahoo lookup due to API change (thanks github.com/kynesun).
* Fix: problem with Mongoid field aliases not being respected.
* Fix: :exclude option to .near scope when primary key != :id (thanks github.com/smisml).
* Much code refactoring (added Geocoder::Query class and Geocoder::Sql module).

1.1.3 (2012 Aug 26)
-------------------

* Add support for Mapquest geocoding service (thanks github.com/razorinc).
* Add :test lookup for easy testing of apps using Geocoder (thanks github.com/mguterl).
* Add #precision method to Yandex results (thanks github.com/gemaker).
* Add support for raising :all exceptions (thanks github.com/andyvb).
* Add exceptions for certain Google geocoder responses (thanks github.com/andyvb).
* Add Travis-CI integration (thanks github.com/petergoldstein).
* Fix: unit config was not working with SQLite (thanks github.com/balvig).
* Fix: get tests to pass under Jruby (thanks github.com/petergoldstein).
* Fix: bug in distance_from_sql method (error occurred when coordinates not found).
* Fix: incompatibility with Mongoid 3.0.x (thanks github.com/petergoldstein).

1.1.2 (2012 May 24)
-------------------

* Add ability to specify default units and distance calculation method (thanks github.com/abravalheri).
* Add new (optional) configuration syntax (thanks github.com/abravalheri).
* Add support for cache stores that provide :get and :set methods.
* Add support for custom HTTP request headers (thanks github.com/robotmay).
* Add Result#cache_hit attribute (thanks github.com/s01ipsist).
* Fix: rake geocode:all wasn't properly loading namespaced classes.
* Fix: properly recognize IP addresses with ::ffff: prefix (thanks github.com/brian-ewell).
* Fix: avoid exception during calculations when coordinates not known (thanks github.com/flori).

1.1.1 (2012 Feb 16)
-------------------

* Add distance_from_sql class method to geocoded class (thanks github.com/dwilkie).
* Add OverQueryLimitError and raise when relevant for Google lookup.
* Fix: don't cache API data if response indicates an error.
* Fix: within_bounding_box now uses correct lat/lon DB columns (thanks github.com/kongo).
* Fix: error accessing city in some cases with Yandex result (thanks github.com/kor6n and sld).

1.1.0 (2011 Dec 3)
------------------

* A block passed to geocoded_by is now always executed, even if the geocoding service returns no results. This means you need to make sure you have results before trying to assign data to your object.
* Fix issues with joins and row counts (issues #49, 86, and 108) by not using GROUP BY clause with ActiveRecord scopes.
* Fix incorrect object ID when join used (fixes issue #140).
* Fix calculation of bounding box which spans 180th meridian (thanks github.com/hwuethrich).
* Add within_bounding_box scope for ActiveRecord-based models (thanks github.com/gavinhughes and dbloete).
* Add option to raise Geocoder::OverQueryLimitError for Google geocoding service.
* Add support for Nominatim geocoding service (thanks github.com/wranglerdriver).
* Add support for API key to Geocoder.ca geocoding service (thanks github.com/ryanLonac).
* Add support for state to Yandex results (thanks github.com/tipugin).

1.0.5 (2011 Oct 26)
-------------------

* Fix error with `rake assets:precompile` (thanks github.com/Sush).
* Fix HTTPS support (thanks github.com/rsanheim).
* Improve cache interface.

1.0.4 (2011 Sep 18)
-------------------

* Remove klass method from rake task, which could conflict with app methods (thanks github.com/mguterl).

1.0.3 (2011 Sep 17)
-------------------

* Add support for Google Premier geocoding service (thanks github.com/steveh).
* Update Google API URL (thanks github.com/soorajb).
* Allow rescue from timeout with FreeGeoIP (thanks github.com/lukeledet).
* Fix: rake assets:precompile (Rails 3.1) not working in some situations.
* Fix: stop double-adjusting units when using kilometers (thanks github.com/hairyheron).

1.0.2 (2011 June 25)
--------------------

* Add support for MongoMapper (thanks github.com/spagalloco).
* Fix: user-specified coordinates field wasn't working with Mongoid (thanks github.com/thisduck).
* Fix: invalid location given to near scope was returning all results (Active Record) or error (Mongoid) (thanks github.com/ogennadi).

1.0.1 (2011 May 17)
-------------------

* Add option to not rescue from certain exceptions (thanks github.com/ahmedrb).
* Fix STI child/parent geocoding bug (thanks github.com/ogennadi).
* Other bugfixes.

1.0.0 (2011 May 9)
------------------

* Add command line interface.
* Add support for local proxy (thanks github.com/Olivier).
* Add support for Yandex.ru geocoding service.
* Add support for Bing geocoding service (thanks github.com/astevens).
* Fix single table inheritance bug (reported by github.com/enrico).
* Fix bug when Google result supplies no city (thanks github.com/jkeen).

0.9.13 (2011 Apr 11)
--------------------

* Fix "can't find special index: 2d" error when using Mongoid with Ruby 1.8.

0.9.12 (2011 Apr 6)
-------------------

* Add support for Mongoid.
* Add bearing_to/from methods to geocoded objects.
* Improve SQLite's distance calculation heuristic.
* Fix: Geocoder::Calculations.geographic_center was modifying its argument in-place (reported by github.com/joelmats).
* Fix: sort 'near' query results by distance when using SQLite.
* Clean up input: search for coordinates as a string with space after comma yields zero results from Google. Now we get rid of any such space before sending the query.
* DEPRECATION: Geocoder.near should not take <tt>:limit</tt> or <tt>:offset</tt> options.
* DEPRECATION: Change argument format of all methods that take lat/lon as separate arguments. Now you must pass the coordinates as an array [lat,lon], but you may alternatively pass a address string (will look up coordinates) or a geocoded object (or any object that implements a to_coordinates method which returns a [lat,lon] array).

0.9.11 (2011 Mar 25)
--------------------

* Add support for result caching.
* Add support for Geocoder.ca geocoding service.
* Add +bearing+ attribute to objects returned by geo-aware queries (thanks github.com/matellis).
* Add config setting: language.
* Add config settings: +use_https+, +google_api_key+ (thanks github.com/svesely).
* DEPRECATION: <tt>Geocoder.search</tt> now returns an array instead of a single result.
* DEPRECATION: <tt>obj.nearbys</tt> second argument is now an options hash (instead of units). Please change <tt>obj.nearbys(20, :km)</tt> to: <tt>obj.nearbys(20, :units => :km)</tt>.

0.9.10 (2011 Mar 9)
-------------------

* Fix broken scopes (github.com/mikepinde).
* Fix broken Ruby 1.9 and JRuby compatibility (don't require json gem).

0.9.9 (2011 Mar 9)
------------------

* Add support for IP address geocoding via FreeGeoIp.net.
* Add support for Yahoo PlaceFinder geocoding API.
* Add support for custom geocoder data handling by passing a block to geocoded_by or reverse_geocoded_by.
* Add <tt>Rack::Request#location</tt> method for geocoding user's IP address.
* Change gem name to geocoder (no more rails-geocoder).
* Gem now works outside of Rails.
* DEPRECATION: +fetch_coordinates+ no longer takes an argument.
* DEPRECATION: +fetch_address+ no longer takes an argument.
* DEPRECATION: <tt>Geocoder.search</tt> now returns a single result instead of an array.
* DEPRECATION: <tt>fetch_coordinates!</tt> has been superceded by +geocode+ (then save your object manually).
* DEPRECATION: <tt>fetch_address!</tt> has been superceded by +reverse_geocode+ (then save your object manually).
* Fix: don't die when trying to get coordinates with a nil address (github.com/zmack).

0.9.8 (2011 Feb 8)
------------------

* Include <tt>geocode:all</tt> Rake task in gem (was missing!).
* Add <tt>Geocoder.search</tt> for access to Google's full response.
* Add ability to configure Google connection timeout.
* Emit warnings on Google connection problems and errors.
* Refactor: insert Geocoder into ActiveRecord via Railtie.

0.9.7 (2011 Feb 1)
------------------

* Add reverse geocoding (+reverse_geocoded_by+).
* Prevent exception (uninitialized constant Geocoder::Net) when net/http not already required (github.com/sleepycat).
* Refactor: split monolithic Geocoder module into several smaller ones.

0.9.6 (2011 Jan 19)
-------------------

* Fix incompatibility with will_paginate gem.
* Include table names in GROUP BY clause of nearby scope to avoid ambiguity in joins (github.com/matchu).

0.9.5 (2010 Oct 15)
-------------------

* Fix broken PostgreSQL compatibility (now 100% compatible).
* Switch from Google's XML to JSON geocoding API.
* Separate Rails 2 and Rails 3-compatible branches.
* Don't allow :conditions hash in 'options' argument to 'nearbys' method (was deprecated in 0.9.3).

0.9.4 (2010 Aug 2)
------------------

* Google Maps API key no longer required (uses geocoder v3).

0.9.3 (2010 Aug 2)
------------------

* Fix incompatibility with Rails 3 RC 1.
* Deprecate 'options' argument to 'nearbys' method.
* Allow inclusion of 'nearbys' in Arel method chains.

0.9.2 (2010 Jun 3)
------------------

* Fix LIMIT clause bug in PostgreSQL (reported by github.com/kenzie).

0.9.1 (2010 May 4)
------------------

* Use scope instead of named_scope in Rails 3.

0.9.0 (2010 Apr 2)
------------------

* Fix bug in PostgreSQL support (caused "PGError: ERROR:  column "distance" does not exist"), reported by github.com/developish.

0.8.9 (2010 Feb 11)
-------------------

* Add Rails 3 compatibility.
* Avoid querying Google when query would be an empty string.

0.8.8 (2009 Dec 7)
------------------

* Automatically select a less accurate but compatible distance algorithm when SQLite database detected (fixes SQLite incompatibility).

0.8.7 (2009 Nov 4)
------------------

* Added Geocoder.geographic_center method.
* Replaced _get_coordinates class method with read_coordinates instance method.

0.8.6 (2009 Oct 27)
-------------------

* The fetch_coordinates method now assigns coordinates to attributes (behaves like fetch_coordinates! used to) and fetch_coordinates! both assigns and saves the attributes.
* Added geocode:all rake task.

0.8.5 (2009 Oct 26)
-------------------

* Avoid calling deprecated method from within Geocoder itself.

0.8.4 (2009 Oct 23)
-------------------

* Deprecate <tt>find_near</tt> class method in favor of +near+ named scope.

0.8.3 (2009 Oct 23)
-------------------

* Update Google URL query string parameter to reflect recent changes in Google's API.

0.8.2 (2009 Oct 12)
-------------------

* Allow a model's geocoder search string method to be something other than an ActiveRecord attribute.
* Clean up documentation.

0.8.1 (2009 Oct 8)
------------------

* Extract XML-fetching code from <tt>Geocoder.search</tt> and place in Geocoder._fetch_xml (for ease of mocking).
* Add tests for coordinate-fetching instance methods.

0.8.0 (2009 Oct 1)
------------------

First release.
