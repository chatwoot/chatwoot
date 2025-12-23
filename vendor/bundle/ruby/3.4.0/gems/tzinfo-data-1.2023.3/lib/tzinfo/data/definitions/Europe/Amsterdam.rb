# encoding: UTF-8

# This file contains data derived from the IANA Time Zone Database
# (https://www.iana.org/time-zones).

module TZInfo
  module Data
    module Definitions
      module Europe
        module Amsterdam
          include TimezoneDefinition
          
          linked_timezone 'Europe/Amsterdam', 'Europe/Brussels'
        end
      end
    end
  end
end
