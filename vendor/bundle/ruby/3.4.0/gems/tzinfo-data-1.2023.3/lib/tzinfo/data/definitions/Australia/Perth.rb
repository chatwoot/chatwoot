# encoding: UTF-8

# This file contains data derived from the IANA Time Zone Database
# (https://www.iana.org/time-zones).

module TZInfo
  module Data
    module Definitions
      module Australia
        module Perth
          include TimezoneDefinition
          
          timezone 'Australia/Perth' do |tz|
            tz.offset :o0, 27804, 0, :LMT
            tz.offset :o1, 28800, 0, :AWST
            tz.offset :o2, 28800, 3600, :AWDT
            
            tz.transition 1895, 11, :o1, -2337925404, 17377402883, 7200
            tz.transition 1916, 12, :o2, -1672552800, 9684917, 4
            tz.transition 1917, 3, :o1, -1665381600, 9685249, 4
            tz.transition 1941, 12, :o2, -883634400, 9721441, 4
            tz.transition 1942, 3, :o1, -876117600, 9721789, 4
            tz.transition 1942, 9, :o2, -860392800, 9722517, 4
            tz.transition 1943, 3, :o1, -844668000, 9723245, 4
            tz.transition 1974, 10, :o2, 152042400
            tz.transition 1975, 3, :o1, 162928800
            tz.transition 1983, 10, :o2, 436298400
            tz.transition 1984, 3, :o1, 447184800
            tz.transition 1991, 11, :o2, 690314400
            tz.transition 1992, 2, :o1, 699386400
            tz.transition 2006, 12, :o2, 1165082400
            tz.transition 2007, 3, :o1, 1174759200
            tz.transition 2007, 10, :o2, 1193508000
            tz.transition 2008, 3, :o1, 1206813600
            tz.transition 2008, 10, :o2, 1224957600
            tz.transition 2009, 3, :o1, 1238263200
          end
        end
      end
    end
  end
end
