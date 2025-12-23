# encoding: UTF-8

# This file contains data derived from the IANA Time Zone Database
# (https://www.iana.org/time-zones).

module TZInfo
  module Data
    module Definitions
      module America
        module Guyana
          include TimezoneDefinition
          
          timezone 'America/Guyana' do |tz|
            tz.offset :o0, -13959, 0, :LMT
            tz.offset :o1, -14400, 0, :'-04'
            tz.offset :o2, -13500, 0, :'-0345'
            tz.offset :o3, -10800, 0, :'-03'
            
            tz.transition 1911, 8, :o1, -1843589241, 7741598917, 3200
            tz.transition 1915, 3, :o2, -1730577600, 7261673, 3
            tz.transition 1975, 8, :o3, 176096700
            tz.transition 1992, 3, :o1, 701841600
          end
        end
      end
    end
  end
end
