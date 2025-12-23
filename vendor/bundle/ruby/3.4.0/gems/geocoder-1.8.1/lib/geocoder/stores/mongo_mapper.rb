require 'geocoder/stores/base'
require 'geocoder/stores/mongo_base'

module Geocoder::Store
  module MongoMapper
    include Base
    include MongoBase

    def self.included(base)
      MongoBase.included_by_model(base)
    end
  end
end
