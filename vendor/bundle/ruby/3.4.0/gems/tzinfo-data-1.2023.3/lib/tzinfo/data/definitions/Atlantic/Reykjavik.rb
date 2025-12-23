# encoding: UTF-8

# This file contains data derived from the IANA Time Zone Database
# (https://www.iana.org/time-zones).

module TZInfo
  module Data
    module Definitions
      module Atlantic
        module Reykjavik
          include TimezoneDefinition
          
          linked_timezone 'Atlantic/Reykjavik', 'Africa/Abidjan'
        end
      end
    end
  end
end
