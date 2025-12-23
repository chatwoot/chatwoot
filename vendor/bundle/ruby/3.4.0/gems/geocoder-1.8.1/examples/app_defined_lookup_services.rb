# To extend the Geocoder with additional lookups that come from the application,
# not shipped with the gem, define a "child" lookup in your application, based on existing one.
# This is required because the Geocoder::Configuration is a Singleton and stores one api key per lookup.

# in app/libs/geocoder/lookup/my_preciousss.rb
module Geocoder::Lookup
  class MyPreciousss < Google
  end
end

# Update Geocoder's street_services on initialize:
# config/initializers/geocoder.rb
Geocoder::Lookup.street_services << :my_preciousss

# Override the configuration when necessary (e.g. provide separate Google API key for the account):
Geocoder.configure(my_preciousss: { api_key: 'abcdef' })

# Lastly, search using your custom lookup service/api keys
Geocoder.search("Paris", lookup: :my_preciousss)

# This is useful when we have groups of users in the application who use Google paid services
# and we want to properly separate them and allow using individual API KEYS or timeouts.
