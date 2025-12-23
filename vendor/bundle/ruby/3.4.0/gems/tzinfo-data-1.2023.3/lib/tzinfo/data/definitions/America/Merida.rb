# encoding: UTF-8

# This file contains data derived from the IANA Time Zone Database
# (https://www.iana.org/time-zones).

module TZInfo
  module Data
    module Definitions
      module America
        module Merida
          include TimezoneDefinition
          
          timezone 'America/Merida' do |tz|
            tz.offset :o0, -21508, 0, :LMT
            tz.offset :o1, -21600, 0, :CST
            tz.offset :o2, -18000, 0, :EST
            tz.offset :o3, -21600, 3600, :CDT
            
            tz.transition 1922, 1, :o1, -1514743200, 9692223, 4
            tz.transition 1981, 12, :o2, 377935200
            tz.transition 1982, 12, :o1, 407653200
            tz.transition 1996, 4, :o3, 828864000
            tz.transition 1996, 10, :o1, 846399600
            tz.transition 1997, 4, :o3, 860313600
            tz.transition 1997, 10, :o1, 877849200
            tz.transition 1998, 4, :o3, 891763200
            tz.transition 1998, 10, :o1, 909298800
            tz.transition 1999, 4, :o3, 923212800
            tz.transition 1999, 10, :o1, 941353200
            tz.transition 2000, 4, :o3, 954662400
            tz.transition 2000, 10, :o1, 972802800
            tz.transition 2001, 5, :o3, 989136000
            tz.transition 2001, 9, :o1, 1001833200
            tz.transition 2002, 4, :o3, 1018166400
            tz.transition 2002, 10, :o1, 1035702000
            tz.transition 2003, 4, :o3, 1049616000
            tz.transition 2003, 10, :o1, 1067151600
            tz.transition 2004, 4, :o3, 1081065600
            tz.transition 2004, 10, :o1, 1099206000
            tz.transition 2005, 4, :o3, 1112515200
            tz.transition 2005, 10, :o1, 1130655600
            tz.transition 2006, 4, :o3, 1143964800
            tz.transition 2006, 10, :o1, 1162105200
            tz.transition 2007, 4, :o3, 1175414400
            tz.transition 2007, 10, :o1, 1193554800
            tz.transition 2008, 4, :o3, 1207468800
            tz.transition 2008, 10, :o1, 1225004400
            tz.transition 2009, 4, :o3, 1238918400
            tz.transition 2009, 10, :o1, 1256454000
            tz.transition 2010, 4, :o3, 1270368000
            tz.transition 2010, 10, :o1, 1288508400
            tz.transition 2011, 4, :o3, 1301817600
            tz.transition 2011, 10, :o1, 1319958000
            tz.transition 2012, 4, :o3, 1333267200
            tz.transition 2012, 10, :o1, 1351407600
            tz.transition 2013, 4, :o3, 1365321600
            tz.transition 2013, 10, :o1, 1382857200
            tz.transition 2014, 4, :o3, 1396771200
            tz.transition 2014, 10, :o1, 1414306800
            tz.transition 2015, 4, :o3, 1428220800
            tz.transition 2015, 10, :o1, 1445756400
            tz.transition 2016, 4, :o3, 1459670400
            tz.transition 2016, 10, :o1, 1477810800
            tz.transition 2017, 4, :o3, 1491120000
            tz.transition 2017, 10, :o1, 1509260400
            tz.transition 2018, 4, :o3, 1522569600
            tz.transition 2018, 10, :o1, 1540710000
            tz.transition 2019, 4, :o3, 1554624000
            tz.transition 2019, 10, :o1, 1572159600
            tz.transition 2020, 4, :o3, 1586073600
            tz.transition 2020, 10, :o1, 1603609200
            tz.transition 2021, 4, :o3, 1617523200
            tz.transition 2021, 10, :o1, 1635663600
            tz.transition 2022, 4, :o3, 1648972800
            tz.transition 2022, 10, :o1, 1667113200
          end
        end
      end
    end
  end
end
