# encoding: UTF-8

# This file contains data derived from the IANA Time Zone Database
# (https://www.iana.org/time-zones).

module TZInfo
  module Data
    module Definitions
      module Pacific
        module Wake
          include TimezoneDefinition
          
          linked_timezone 'Pacific/Wake', 'Pacific/Tarawa'
        end
      end
    end
  end
end
