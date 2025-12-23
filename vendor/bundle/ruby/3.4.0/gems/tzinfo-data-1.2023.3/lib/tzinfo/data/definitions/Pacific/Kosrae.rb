# encoding: UTF-8

# This file contains data derived from the IANA Time Zone Database
# (https://www.iana.org/time-zones).

module TZInfo
  module Data
    module Definitions
      module Pacific
        module Kosrae
          include TimezoneDefinition
          
          timezone 'Pacific/Kosrae' do |tz|
            tz.offset :o0, -47284, 0, :LMT
            tz.offset :o1, 39116, 0, :LMT
            tz.offset :o2, 39600, 0, :'+11'
            tz.offset :o3, 32400, 0, :'+09'
            tz.offset :o4, 36000, 0, :'+10'
            tz.offset :o5, 43200, 0, :'+12'
            
            tz.transition 1844, 12, :o1, -3944631116, 51730532221, 21600
            tz.transition 1900, 12, :o2, -2177491916, 52172317021, 21600
            tz.transition 1914, 9, :o3, -1743678000, 58089745, 24
            tz.transition 1919, 1, :o2, -1606813200, 19375921, 8
            tz.transition 1936, 12, :o4, -1041418800, 58284817, 24
            tz.transition 1941, 3, :o3, -907408800, 29161021, 12
            tz.transition 1945, 7, :o2, -770634000, 19453345, 8
            tz.transition 1969, 9, :o5, -7988400, 58571881, 24
            tz.transition 1998, 12, :o2, 915105600
          end
        end
      end
    end
  end
end
