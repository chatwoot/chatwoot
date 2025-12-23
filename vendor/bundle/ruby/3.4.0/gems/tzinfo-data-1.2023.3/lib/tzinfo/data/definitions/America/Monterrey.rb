# encoding: UTF-8

# This file contains data derived from the IANA Time Zone Database
# (https://www.iana.org/time-zones).

module TZInfo
  module Data
    module Definitions
      module America
        module Monterrey
          include TimezoneDefinition
          
          timezone 'America/Monterrey' do |tz|
            tz.offset :o0, -24076, 0, :LMT
            tz.offset :o1, -21600, 0, :CST
            tz.offset :o2, -21600, 3600, :CDT
            
            tz.transition 1922, 1, :o1, -1514743200, 9692223, 4
            tz.transition 1988, 4, :o2, 576057600
            tz.transition 1988, 10, :o1, 594198000
            tz.transition 1996, 4, :o2, 828864000
            tz.transition 1996, 10, :o1, 846399600
            tz.transition 1997, 4, :o2, 860313600
            tz.transition 1997, 10, :o1, 877849200
            tz.transition 1998, 4, :o2, 891763200
            tz.transition 1998, 10, :o1, 909298800
            tz.transition 1999, 4, :o2, 923212800
            tz.transition 1999, 10, :o1, 941353200
            tz.transition 2000, 4, :o2, 954662400
            tz.transition 2000, 10, :o1, 972802800
            tz.transition 2001, 5, :o2, 989136000
            tz.transition 2001, 9, :o1, 1001833200
            tz.transition 2002, 4, :o2, 1018166400
            tz.transition 2002, 10, :o1, 1035702000
            tz.transition 2003, 4, :o2, 1049616000
            tz.transition 2003, 10, :o1, 1067151600
            tz.transition 2004, 4, :o2, 1081065600
            tz.transition 2004, 10, :o1, 1099206000
            tz.transition 2005, 4, :o2, 1112515200
            tz.transition 2005, 10, :o1, 1130655600
            tz.transition 2006, 4, :o2, 1143964800
            tz.transition 2006, 10, :o1, 1162105200
            tz.transition 2007, 4, :o2, 1175414400
            tz.transition 2007, 10, :o1, 1193554800
            tz.transition 2008, 4, :o2, 1207468800
            tz.transition 2008, 10, :o1, 1225004400
            tz.transition 2009, 4, :o2, 1238918400
            tz.transition 2009, 10, :o1, 1256454000
            tz.transition 2010, 4, :o2, 1270368000
            tz.transition 2010, 10, :o1, 1288508400
            tz.transition 2011, 4, :o2, 1301817600
            tz.transition 2011, 10, :o1, 1319958000
            tz.transition 2012, 4, :o2, 1333267200
            tz.transition 2012, 10, :o1, 1351407600
            tz.transition 2013, 4, :o2, 1365321600
            tz.transition 2013, 10, :o1, 1382857200
            tz.transition 2014, 4, :o2, 1396771200
            tz.transition 2014, 10, :o1, 1414306800
            tz.transition 2015, 4, :o2, 1428220800
            tz.transition 2015, 10, :o1, 1445756400
            tz.transition 2016, 4, :o2, 1459670400
            tz.transition 2016, 10, :o1, 1477810800
            tz.transition 2017, 4, :o2, 1491120000
            tz.transition 2017, 10, :o1, 1509260400
            tz.transition 2018, 4, :o2, 1522569600
            tz.transition 2018, 10, :o1, 1540710000
            tz.transition 2019, 4, :o2, 1554624000
            tz.transition 2019, 10, :o1, 1572159600
            tz.transition 2020, 4, :o2, 1586073600
            tz.transition 2020, 10, :o1, 1603609200
            tz.transition 2021, 4, :o2, 1617523200
            tz.transition 2021, 10, :o1, 1635663600
            tz.transition 2022, 4, :o2, 1648972800
            tz.transition 2022, 10, :o1, 1667113200
          end
        end
      end
    end
  end
end
