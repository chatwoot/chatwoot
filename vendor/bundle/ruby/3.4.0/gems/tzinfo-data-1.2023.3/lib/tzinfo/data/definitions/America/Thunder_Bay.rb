# encoding: UTF-8

# This file contains data derived from the IANA Time Zone Database
# (https://www.iana.org/time-zones).

module TZInfo
  module Data
    module Definitions
      module America
        module Thunder_Bay
          include TimezoneDefinition
          
          linked_timezone 'America/Thunder_Bay', 'America/Toronto'
        end
      end
    end
  end
end
