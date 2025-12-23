# encoding: UTF-8

# This file contains data derived from the IANA Time Zone Database
# (https://www.iana.org/time-zones).

module TZInfo
  module Data
    module Definitions
      module Pacific
        module Ponape
          include TimezoneDefinition
          
          linked_timezone 'Pacific/Ponape', 'Pacific/Guadalcanal'
        end
      end
    end
  end
end
