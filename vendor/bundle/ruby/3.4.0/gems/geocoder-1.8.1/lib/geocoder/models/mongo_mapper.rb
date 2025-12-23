require 'geocoder/models/base'
require 'geocoder/models/mongo_base'

module Geocoder
  module Model
    module MongoMapper
      include Base
      include MongoBase

      def self.included(base); base.extend(self); end

      private # --------------------------------------------------------------

      def geocoder_file_name;   "mongo_mapper"; end
      def geocoder_module_name; "MongoMapper"; end

      def geocoder_init(options)
        super(options)
        if options[:skip_index] == false
          ensure_index [[ geocoder_options[:coordinates], Mongo::GEO2D ]],
            :min => -180, :max => 180 # create 2d index
        end
      end
    end
  end
end
