# encoding: UTF-8

# This file contains data derived from the IANA Time Zone Database
# (https://www.iana.org/time-zones).

module TZInfo
  module Data
    module Definitions
      module America
        module Mexico_City
          include TimezoneDefinition
          
          timezone 'America/Mexico_City' do |tz|
            tz.offset :o0, -23796, 0, :LMT
            tz.offset :o1, -25200, 0, :MST
            tz.offset :o2, -21600, 0, :CST
            tz.offset :o3, -25200, 3600, :MDT
            tz.offset :o4, -21600, 3600, :CDT
            tz.offset :o5, -21600, 3600, :CWT
            
            tz.transition 1922, 1, :o1, -1514739600, 58153339, 24
            tz.transition 1927, 6, :o2, -1343066400, 9700171, 4
            tz.transition 1930, 11, :o1, -1234807200, 9705183, 4
            tz.transition 1931, 5, :o3, -1220292000, 9705855, 4
            tz.transition 1931, 10, :o1, -1207159200, 9706463, 4
            tz.transition 1932, 4, :o2, -1191344400, 58243171, 24
            tz.transition 1939, 2, :o4, -975261600, 9717199, 4
            tz.transition 1939, 6, :o2, -963169200, 58306553, 24
            tz.transition 1940, 12, :o4, -917114400, 9719891, 4
            tz.transition 1941, 4, :o2, -907354800, 58322057, 24
            tz.transition 1943, 12, :o5, -821901600, 9724299, 4
            tz.transition 1944, 5, :o2, -810068400, 58349081, 24
            tz.transition 1950, 2, :o4, -627501600, 9733299, 4
            tz.transition 1950, 7, :o2, -612990000, 58403825, 24
            tz.transition 1996, 4, :o4, 828864000
            tz.transition 1996, 10, :o2, 846399600
            tz.transition 1997, 4, :o4, 860313600
            tz.transition 1997, 10, :o2, 877849200
            tz.transition 1998, 4, :o4, 891763200
            tz.transition 1998, 10, :o2, 909298800
            tz.transition 1999, 4, :o4, 923212800
            tz.transition 1999, 10, :o2, 941353200
            tz.transition 2000, 4, :o4, 954662400
            tz.transition 2000, 10, :o2, 972802800
            tz.transition 2001, 5, :o4, 989136000
            tz.transition 2001, 9, :o2, 1001833200
            tz.transition 2002, 4, :o4, 1018166400
            tz.transition 2002, 10, :o2, 1035702000
            tz.transition 2003, 4, :o4, 1049616000
            tz.transition 2003, 10, :o2, 1067151600
            tz.transition 2004, 4, :o4, 1081065600
            tz.transition 2004, 10, :o2, 1099206000
            tz.transition 2005, 4, :o4, 1112515200
            tz.transition 2005, 10, :o2, 1130655600
            tz.transition 2006, 4, :o4, 1143964800
            tz.transition 2006, 10, :o2, 1162105200
            tz.transition 2007, 4, :o4, 1175414400
            tz.transition 2007, 10, :o2, 1193554800
            tz.transition 2008, 4, :o4, 1207468800
            tz.transition 2008, 10, :o2, 1225004400
            tz.transition 2009, 4, :o4, 1238918400
            tz.transition 2009, 10, :o2, 1256454000
            tz.transition 2010, 4, :o4, 1270368000
            tz.transition 2010, 10, :o2, 1288508400
            tz.transition 2011, 4, :o4, 1301817600
            tz.transition 2011, 10, :o2, 1319958000
            tz.transition 2012, 4, :o4, 1333267200
            tz.transition 2012, 10, :o2, 1351407600
            tz.transition 2013, 4, :o4, 1365321600
            tz.transition 2013, 10, :o2, 1382857200
            tz.transition 2014, 4, :o4, 1396771200
            tz.transition 2014, 10, :o2, 1414306800
            tz.transition 2015, 4, :o4, 1428220800
            tz.transition 2015, 10, :o2, 1445756400
            tz.transition 2016, 4, :o4, 1459670400
            tz.transition 2016, 10, :o2, 1477810800
            tz.transition 2017, 4, :o4, 1491120000
            tz.transition 2017, 10, :o2, 1509260400
            tz.transition 2018, 4, :o4, 1522569600
            tz.transition 2018, 10, :o2, 1540710000
            tz.transition 2019, 4, :o4, 1554624000
            tz.transition 2019, 10, :o2, 1572159600
            tz.transition 2020, 4, :o4, 1586073600
            tz.transition 2020, 10, :o2, 1603609200
            tz.transition 2021, 4, :o4, 1617523200
            tz.transition 2021, 10, :o2, 1635663600
            tz.transition 2022, 4, :o4, 1648972800
            tz.transition 2022, 10, :o2, 1667113200
          end
        end
      end
    end
  end
end
