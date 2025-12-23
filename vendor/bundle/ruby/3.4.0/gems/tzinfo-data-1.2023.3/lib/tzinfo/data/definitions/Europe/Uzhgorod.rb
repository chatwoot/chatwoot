# encoding: UTF-8

# This file contains data derived from the IANA Time Zone Database
# (https://www.iana.org/time-zones).

module TZInfo
  module Data
    module Definitions
      module Europe
        module Uzhgorod
          include TimezoneDefinition
          
          linked_timezone 'Europe/Uzhgorod', 'Europe/Kyiv'
        end
      end
    end
  end
end
