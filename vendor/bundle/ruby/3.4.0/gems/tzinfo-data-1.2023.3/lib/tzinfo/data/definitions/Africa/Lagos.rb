# encoding: UTF-8

# This file contains data derived from the IANA Time Zone Database
# (https://www.iana.org/time-zones).

module TZInfo
  module Data
    module Definitions
      module Africa
        module Lagos
          include TimezoneDefinition
          
          timezone 'Africa/Lagos' do |tz|
            tz.offset :o0, 815, 0, :LMT
            tz.offset :o1, 0, 0, :GMT
            tz.offset :o2, 1800, 0, :'+0030'
            tz.offset :o3, 3600, 0, :WAT
            
            tz.transition 1905, 6, :o1, -2035584815, 41766235037, 17280
            tz.transition 1908, 7, :o0, -1940889600, 4836247, 2
            tz.transition 1913, 12, :o2, -1767226415, 41819906717, 17280
            tz.transition 1919, 8, :o3, -1588465800, 116265719, 48
          end
        end
      end
    end
  end
end
