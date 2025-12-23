# encoding: UTF-8

# This file contains data derived from the IANA Time Zone Database
# (https://www.iana.org/time-zones).

module TZInfo
  module Data
    module Definitions
      module Pacific
        module Kanton
          include TimezoneDefinition
          
          timezone 'Pacific/Kanton' do |tz|
            tz.offset :o0, 0, 0, :'-00'
            tz.offset :o1, -43200, 0, :'-12'
            tz.offset :o2, -39600, 0, :'-11'
            tz.offset :o3, 46800, 0, :'+13'
            
            tz.transition 1937, 8, :o1, -1020470400, 4857553, 2
            tz.transition 1979, 10, :o2, 307627200
            tz.transition 1994, 12, :o3, 788871600
          end
        end
      end
    end
  end
end
