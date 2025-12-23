require "geocoder/configuration"
require "geocoder/logger"
require "geocoder/kernel_logger"
require "geocoder/query"
require "geocoder/calculations"
require "geocoder/exceptions"
require "geocoder/cache"
require "geocoder/request"
require "geocoder/lookup"
require "geocoder/ip_address"
require "geocoder/models/active_record" if defined?(::ActiveRecord)
require "geocoder/models/mongoid" if defined?(::Mongoid)
require "geocoder/models/mongo_mapper" if defined?(::MongoMapper)

module Geocoder

  ##
  # Search for information about an address or a set of coordinates.
  #
  def self.search(query, options = {})
    query = Geocoder::Query.new(query, options) unless query.is_a?(Geocoder::Query)
    query.blank? ? [] : query.execute
  end

  ##
  # Look up the coordinates of the given street or IP address.
  #
  def self.coordinates(address, options = {})
    if (results = search(address, options)).size > 0
      results.first.coordinates
    end
  end

  ##
  # Look up the address of the given coordinates ([lat,lon])
  # or IP address (string).
  #
  def self.address(query, options = {})
    if (results = search(query, options)).size > 0
      results.first.address
    end
  end
end

# load Railtie if Rails exists
if defined?(Rails)
  require "geocoder/railtie"
end
