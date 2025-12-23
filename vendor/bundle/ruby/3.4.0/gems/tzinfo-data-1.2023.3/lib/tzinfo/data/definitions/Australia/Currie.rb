# encoding: UTF-8

# This file contains data derived from the IANA Time Zone Database
# (https://www.iana.org/time-zones).

module TZInfo
  module Data
    module Definitions
      module Australia
        module Currie
          include TimezoneDefinition
          
          linked_timezone 'Australia/Currie', 'Australia/Hobart'
        end
      end
    end
  end
end
