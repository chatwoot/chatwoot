# encoding: UTF-8

# This file contains data derived from the IANA Time Zone Database
# (https://www.iana.org/time-zones).

module TZInfo
  module Data
    module Definitions
      module Europe
        module Copenhagen
          include TimezoneDefinition
          
          linked_timezone 'Europe/Copenhagen', 'Europe/Berlin'
        end
      end
    end
  end
end
