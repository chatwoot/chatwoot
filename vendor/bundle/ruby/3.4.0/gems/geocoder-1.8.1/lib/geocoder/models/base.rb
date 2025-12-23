module Geocoder

  ##
  # Methods for invoking Geocoder in a model.
  #
  module Model
    module Base

      def geocoder_options
        if defined?(@geocoder_options)
          @geocoder_options
        elsif superclass.respond_to?(:geocoder_options)
          superclass.geocoder_options || { }
        else
          { }
        end
      end

      def geocoded_by
        fail
      end

      def reverse_geocoded_by
        fail
      end

      private # ----------------------------------------------------------------

      def geocoder_init(options)
        unless defined?(@geocoder_options)
          @geocoder_options = {}
          require "geocoder/stores/#{geocoder_file_name}"
          include Geocoder::Store.const_get(geocoder_module_name)
        end
        @geocoder_options.merge! options
      end
    end
  end
end
