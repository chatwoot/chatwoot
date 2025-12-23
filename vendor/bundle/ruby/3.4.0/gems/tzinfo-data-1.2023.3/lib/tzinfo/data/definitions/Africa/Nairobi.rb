# encoding: UTF-8

# This file contains data derived from the IANA Time Zone Database
# (https://www.iana.org/time-zones).

module TZInfo
  module Data
    module Definitions
      module Africa
        module Nairobi
          include TimezoneDefinition
          
          timezone 'Africa/Nairobi' do |tz|
            tz.offset :o0, 8836, 0, :LMT
            tz.offset :o1, 9000, 0, :'+0230'
            tz.offset :o2, 10800, 0, :EAT
            tz.offset :o3, 9900, 0, :'+0245'
            
            tz.transition 1908, 4, :o1, -1946168836, 52230147791, 21600
            tz.transition 1928, 6, :o2, -1309746600, 116420563, 48
            tz.transition 1930, 1, :o1, -1261969200, 19407851, 8
            tz.transition 1936, 12, :o3, -1041388200, 116569651, 48
            tz.transition 1942, 7, :o2, -865305900, 233334949, 96
          end
        end
      end
    end
  end
end
