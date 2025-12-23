# encoding: UTF-8

# This file contains data derived from the IANA Time Zone Database
# (https://www.iana.org/time-zones).

module TZInfo
  module Data
    module Definitions
      module America
        module Rainy_River
          include TimezoneDefinition
          
          linked_timezone 'America/Rainy_River', 'America/Winnipeg'
        end
      end
    end
  end
end
