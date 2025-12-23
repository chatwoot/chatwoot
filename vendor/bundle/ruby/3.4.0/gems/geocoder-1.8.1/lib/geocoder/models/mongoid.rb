require 'geocoder/models/base'
require 'geocoder/models/mongo_base'

module Geocoder
  module Model
    module Mongoid
      include Base
      include MongoBase

      def self.included(base); base.extend(self); end

      private # --------------------------------------------------------------

      def geocoder_file_name;   "mongoid"; end
      def geocoder_module_name; "Mongoid"; end

      def geocoder_init(options)
        super(options)
        if options[:skip_index] == false
          # create 2d index
          if defined?(::Mongoid::VERSION) && ::Mongoid::VERSION >= "3"
            index({ geocoder_options[:coordinates].to_sym => '2d' }, 
                  {:min => -180, :max => 180})
          else
            index [[ geocoder_options[:coordinates], '2d' ]],
              :min => -180, :max => 180
          end
        end
      end
    end
  end
end
