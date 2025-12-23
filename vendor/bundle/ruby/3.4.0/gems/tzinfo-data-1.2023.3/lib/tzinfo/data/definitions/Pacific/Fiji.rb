# encoding: UTF-8

# This file contains data derived from the IANA Time Zone Database
# (https://www.iana.org/time-zones).

module TZInfo
  module Data
    module Definitions
      module Pacific
        module Fiji
          include TimezoneDefinition
          
          timezone 'Pacific/Fiji' do |tz|
            tz.offset :o0, 42944, 0, :LMT
            tz.offset :o1, 43200, 0, :'+12'
            tz.offset :o2, 43200, 3600, :'+13'
            
            tz.transition 1915, 10, :o1, -1709985344, 1634037302, 675
            tz.transition 1998, 10, :o2, 909842400
            tz.transition 1999, 2, :o1, 920124000
            tz.transition 1999, 11, :o2, 941896800
            tz.transition 2000, 2, :o1, 951573600
            tz.transition 2009, 11, :o2, 1259416800
            tz.transition 2010, 3, :o1, 1269698400
            tz.transition 2010, 10, :o2, 1287842400
            tz.transition 2011, 3, :o1, 1299333600
            tz.transition 2011, 10, :o2, 1319292000
            tz.transition 2012, 1, :o1, 1327154400
            tz.transition 2012, 10, :o2, 1350741600
            tz.transition 2013, 1, :o1, 1358604000
            tz.transition 2013, 10, :o2, 1382796000
            tz.transition 2014, 1, :o1, 1390050000
            tz.transition 2014, 11, :o2, 1414850400
            tz.transition 2015, 1, :o1, 1421503200
            tz.transition 2015, 10, :o2, 1446300000
            tz.transition 2016, 1, :o1, 1452952800
            tz.transition 2016, 11, :o2, 1478354400
            tz.transition 2017, 1, :o1, 1484402400
            tz.transition 2017, 11, :o2, 1509804000
            tz.transition 2018, 1, :o1, 1515852000
            tz.transition 2018, 11, :o2, 1541253600
            tz.transition 2019, 1, :o1, 1547301600
            tz.transition 2019, 11, :o2, 1573308000
            tz.transition 2020, 1, :o1, 1578751200
            tz.transition 2020, 12, :o2, 1608386400
            tz.transition 2021, 1, :o1, 1610805600
          end
        end
      end
    end
  end
end
