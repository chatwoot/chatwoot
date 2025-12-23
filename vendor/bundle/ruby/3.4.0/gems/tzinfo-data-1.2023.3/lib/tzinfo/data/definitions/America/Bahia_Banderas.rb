# encoding: UTF-8

# This file contains data derived from the IANA Time Zone Database
# (https://www.iana.org/time-zones).

module TZInfo
  module Data
    module Definitions
      module America
        module Bahia_Banderas
          include TimezoneDefinition
          
          timezone 'America/Bahia_Banderas' do |tz|
            tz.offset :o0, -25260, 0, :LMT
            tz.offset :o1, -25200, 0, :MST
            tz.offset :o2, -21600, 0, :CST
            tz.offset :o3, -25200, 3600, :MDT
            tz.offset :o4, -28800, 0, :PST
            tz.offset :o5, -21600, 3600, :CDT
            
            tz.transition 1922, 1, :o1, -1514739600, 58153339, 24
            tz.transition 1927, 6, :o2, -1343066400, 9700171, 4
            tz.transition 1930, 11, :o1, -1234807200, 9705183, 4
            tz.transition 1931, 5, :o3, -1220292000, 9705855, 4
            tz.transition 1931, 10, :o1, -1207159200, 9706463, 4
            tz.transition 1932, 4, :o2, -1191344400, 58243171, 24
            tz.transition 1942, 4, :o1, -873828000, 9721895, 4
            tz.transition 1949, 1, :o4, -661539600, 58390339, 24
            tz.transition 1970, 1, :o1, 28800
            tz.transition 1996, 4, :o3, 828867600
            tz.transition 1996, 10, :o1, 846403200
            tz.transition 1997, 4, :o3, 860317200
            tz.transition 1997, 10, :o1, 877852800
            tz.transition 1998, 4, :o3, 891766800
            tz.transition 1998, 10, :o1, 909302400
            tz.transition 1999, 4, :o3, 923216400
            tz.transition 1999, 10, :o1, 941356800
            tz.transition 2000, 4, :o3, 954666000
            tz.transition 2000, 10, :o1, 972806400
            tz.transition 2001, 5, :o3, 989139600
            tz.transition 2001, 9, :o1, 1001836800
            tz.transition 2002, 4, :o3, 1018170000
            tz.transition 2002, 10, :o1, 1035705600
            tz.transition 2003, 4, :o3, 1049619600
            tz.transition 2003, 10, :o1, 1067155200
            tz.transition 2004, 4, :o3, 1081069200
            tz.transition 2004, 10, :o1, 1099209600
            tz.transition 2005, 4, :o3, 1112518800
            tz.transition 2005, 10, :o1, 1130659200
            tz.transition 2006, 4, :o3, 1143968400
            tz.transition 2006, 10, :o1, 1162108800
            tz.transition 2007, 4, :o3, 1175418000
            tz.transition 2007, 10, :o1, 1193558400
            tz.transition 2008, 4, :o3, 1207472400
            tz.transition 2008, 10, :o1, 1225008000
            tz.transition 2009, 4, :o3, 1238922000
            tz.transition 2009, 10, :o1, 1256457600
            tz.transition 2010, 4, :o5, 1270371600
            tz.transition 2010, 10, :o2, 1288508400
            tz.transition 2011, 4, :o5, 1301817600
            tz.transition 2011, 10, :o2, 1319958000
            tz.transition 2012, 4, :o5, 1333267200
            tz.transition 2012, 10, :o2, 1351407600
            tz.transition 2013, 4, :o5, 1365321600
            tz.transition 2013, 10, :o2, 1382857200
            tz.transition 2014, 4, :o5, 1396771200
            tz.transition 2014, 10, :o2, 1414306800
            tz.transition 2015, 4, :o5, 1428220800
            tz.transition 2015, 10, :o2, 1445756400
            tz.transition 2016, 4, :o5, 1459670400
            tz.transition 2016, 10, :o2, 1477810800
            tz.transition 2017, 4, :o5, 1491120000
            tz.transition 2017, 10, :o2, 1509260400
            tz.transition 2018, 4, :o5, 1522569600
            tz.transition 2018, 10, :o2, 1540710000
            tz.transition 2019, 4, :o5, 1554624000
            tz.transition 2019, 10, :o2, 1572159600
            tz.transition 2020, 4, :o5, 1586073600
            tz.transition 2020, 10, :o2, 1603609200
            tz.transition 2021, 4, :o5, 1617523200
            tz.transition 2021, 10, :o2, 1635663600
            tz.transition 2022, 4, :o5, 1648972800
            tz.transition 2022, 10, :o2, 1667113200
          end
        end
      end
    end
  end
end
