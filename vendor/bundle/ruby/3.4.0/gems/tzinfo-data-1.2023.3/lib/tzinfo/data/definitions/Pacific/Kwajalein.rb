# encoding: UTF-8

# This file contains data derived from the IANA Time Zone Database
# (https://www.iana.org/time-zones).

module TZInfo
  module Data
    module Definitions
      module Pacific
        module Kwajalein
          include TimezoneDefinition
          
          timezone 'Pacific/Kwajalein' do |tz|
            tz.offset :o0, 40160, 0, :LMT
            tz.offset :o1, 39600, 0, :'+11'
            tz.offset :o2, 36000, 0, :'+10'
            tz.offset :o3, 32400, 0, :'+09'
            tz.offset :o4, -43200, 0, :'-12'
            tz.offset :o5, 43200, 0, :'+12'
            
            tz.transition 1900, 12, :o1, -2177492960, 1304307919, 540
            tz.transition 1936, 12, :o2, -1041418800, 58284817, 24
            tz.transition 1941, 3, :o3, -907408800, 29161021, 12
            tz.transition 1944, 2, :o1, -817462800, 19449009, 8
            tz.transition 1969, 9, :o4, -7988400, 58571881, 24
            tz.transition 1993, 8, :o5, 745934400
          end
        end
      end
    end
  end
end
