# frozen_string_literal: true

module SassC
  module Script
    module ValueConversion
      class Map < Base
        def to_native
          hash = @value.to_h
          native_map = Native::make_map( hash.size )
          hash.each_with_index do |(key, value), index|
            key   = ValueConversion.to_native key
            value = ValueConversion.to_native value
            Native::map_set_key(   native_map, index, key )
            Native::map_set_value( native_map, index, value )
          end
          return native_map
        end
      end
    end
  end
end
