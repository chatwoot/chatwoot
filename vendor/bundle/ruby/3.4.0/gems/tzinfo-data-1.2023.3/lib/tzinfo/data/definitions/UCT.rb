# encoding: UTF-8

# This file contains data derived from the IANA Time Zone Database
# (https://www.iana.org/time-zones).

module TZInfo
  module Data
    module Definitions
      module UCT
        include TimezoneDefinition
        
        linked_timezone 'UCT', 'Etc/UTC'
      end
    end
  end
end
