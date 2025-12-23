# encoding: UTF-8

# This file contains data derived from the IANA Time Zone Database
# (https://www.iana.org/time-zones).

module TZInfo
  module Data
    module Definitions
      module America
        module Guadeloupe
          include TimezoneDefinition
          
          linked_timezone 'America/Guadeloupe', 'America/Puerto_Rico'
        end
      end
    end
  end
end
