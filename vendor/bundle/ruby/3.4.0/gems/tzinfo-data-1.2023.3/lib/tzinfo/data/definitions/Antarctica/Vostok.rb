# encoding: UTF-8

# This file contains data derived from the IANA Time Zone Database
# (https://www.iana.org/time-zones).

module TZInfo
  module Data
    module Definitions
      module Antarctica
        module Vostok
          include TimezoneDefinition
          
          linked_timezone 'Antarctica/Vostok', 'Asia/Urumqi'
        end
      end
    end
  end
end
