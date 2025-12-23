# encoding: UTF-8

# This file contains data derived from the IANA Time Zone Database
# (https://www.iana.org/time-zones).

module TZInfo
  module Data
    module Definitions
      module Pacific
        module Guam
          include TimezoneDefinition
          
          timezone 'Pacific/Guam' do |tz|
            tz.offset :o0, -51660, 0, :LMT
            tz.offset :o1, 34740, 0, :LMT
            tz.offset :o2, 36000, 0, :GST
            tz.offset :o3, 32400, 0, :'+09'
            tz.offset :o4, 36000, 3600, :GDT
            tz.offset :o5, 36000, 0, :ChST
            
            tz.transition 1844, 12, :o1, -3944626740, 1149567407, 480
            tz.transition 1900, 12, :o2, -2177487540, 1159384847, 480
            tz.transition 1941, 12, :o3, -885549600, 29164057, 12
            tz.transition 1944, 7, :o2, -802256400, 19450417, 8
            tz.transition 1959, 6, :o4, -331891200, 14620477, 6
            tz.transition 1961, 1, :o2, -281610000, 19498625, 8
            tz.transition 1967, 8, :o4, -73728000, 14638405, 6
            tz.transition 1969, 1, :o2, -29415540, 3513955741, 1440
            tz.transition 1969, 6, :o4, -16704000, 14642365, 6
            tz.transition 1969, 8, :o2, -10659600, 19523713, 8
            tz.transition 1970, 4, :o4, 9907200
            tz.transition 1970, 9, :o2, 21394800
            tz.transition 1971, 4, :o4, 41356800
            tz.transition 1971, 9, :o2, 52844400
            tz.transition 1973, 12, :o4, 124819200
            tz.transition 1974, 2, :o2, 130863600
            tz.transition 1976, 5, :o4, 201888000
            tz.transition 1976, 8, :o2, 209487660
            tz.transition 1977, 4, :o4, 230659200
            tz.transition 1977, 8, :o2, 241542000
            tz.transition 2000, 12, :o5, 977493600
          end
        end
      end
    end
  end
end
