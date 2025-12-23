# encoding: UTF-8

# This file contains data derived from the IANA Time Zone Database
# (https://www.iana.org/time-zones).

module TZInfo
  module Data
    module Definitions
      module Asia
        module Amman
          include TimezoneDefinition
          
          timezone 'Asia/Amman' do |tz|
            tz.offset :o0, 8624, 0, :LMT
            tz.offset :o1, 7200, 0, :EET
            tz.offset :o2, 7200, 3600, :EEST
            tz.offset :o3, 10800, 0, :'+03'
            
            tz.transition 1930, 12, :o1, -1230776624, 13102248961, 5400
            tz.transition 1973, 6, :o2, 108165600
            tz.transition 1973, 9, :o1, 118270800
            tz.transition 1974, 4, :o2, 136591200
            tz.transition 1974, 9, :o1, 149806800
            tz.transition 1975, 4, :o2, 168127200
            tz.transition 1975, 9, :o1, 181342800
            tz.transition 1976, 4, :o2, 199749600
            tz.transition 1976, 10, :o1, 215643600
            tz.transition 1977, 4, :o2, 231285600
            tz.transition 1977, 9, :o1, 244501200
            tz.transition 1978, 4, :o2, 262735200
            tz.transition 1978, 9, :o1, 275950800
            tz.transition 1985, 3, :o2, 481154400
            tz.transition 1985, 9, :o1, 496962000
            tz.transition 1986, 4, :o2, 512949600
            tz.transition 1986, 10, :o1, 528670800
            tz.transition 1987, 4, :o2, 544399200
            tz.transition 1987, 10, :o1, 560120400
            tz.transition 1988, 3, :o2, 575848800
            tz.transition 1988, 10, :o1, 592174800
            tz.transition 1989, 5, :o2, 610581600
            tz.transition 1989, 10, :o1, 623624400
            tz.transition 1990, 4, :o2, 641167200
            tz.transition 1990, 10, :o1, 655074000
            tz.transition 1991, 4, :o2, 671839200
            tz.transition 1991, 9, :o1, 685918800
            tz.transition 1992, 4, :o2, 702856800
            tz.transition 1992, 10, :o1, 717973200
            tz.transition 1993, 4, :o2, 733701600
            tz.transition 1993, 9, :o1, 749422800
            tz.transition 1994, 3, :o2, 765151200
            tz.transition 1994, 9, :o1, 779662800
            tz.transition 1995, 4, :o2, 797205600
            tz.transition 1995, 9, :o1, 811116000
            tz.transition 1996, 4, :o2, 828655200
            tz.transition 1996, 9, :o1, 843170400
            tz.transition 1997, 4, :o2, 860104800
            tz.transition 1997, 9, :o1, 874620000
            tz.transition 1998, 4, :o2, 891554400
            tz.transition 1998, 9, :o1, 906069600
            tz.transition 1999, 6, :o2, 930780000
            tz.transition 1999, 9, :o1, 938124000
            tz.transition 2000, 3, :o2, 954367200
            tz.transition 2000, 9, :o1, 970178400
            tz.transition 2001, 3, :o2, 985816800
            tz.transition 2001, 9, :o1, 1001628000
            tz.transition 2002, 3, :o2, 1017352800
            tz.transition 2002, 9, :o1, 1033077600
            tz.transition 2003, 3, :o2, 1048802400
            tz.transition 2003, 10, :o1, 1066946400
            tz.transition 2004, 3, :o2, 1080252000
            tz.transition 2004, 10, :o1, 1097791200
            tz.transition 2005, 3, :o2, 1112306400
            tz.transition 2005, 9, :o1, 1128031200
            tz.transition 2006, 3, :o2, 1143756000
            tz.transition 2006, 10, :o1, 1161900000
            tz.transition 2007, 3, :o2, 1175205600
            tz.transition 2007, 10, :o1, 1193349600
            tz.transition 2008, 3, :o2, 1206655200
            tz.transition 2008, 10, :o1, 1225404000
            tz.transition 2009, 3, :o2, 1238104800
            tz.transition 2009, 10, :o1, 1256853600
            tz.transition 2010, 3, :o2, 1269554400
            tz.transition 2010, 10, :o1, 1288303200
            tz.transition 2011, 3, :o2, 1301608800
            tz.transition 2011, 10, :o1, 1319752800
            tz.transition 2012, 3, :o2, 1333058400
            tz.transition 2013, 12, :o1, 1387486800
            tz.transition 2014, 3, :o2, 1395957600
            tz.transition 2014, 10, :o1, 1414706400
            tz.transition 2015, 3, :o2, 1427407200
            tz.transition 2015, 10, :o1, 1446156000
            tz.transition 2016, 3, :o2, 1459461600
            tz.transition 2016, 10, :o1, 1477605600
            tz.transition 2017, 3, :o2, 1490911200
            tz.transition 2017, 10, :o1, 1509055200
            tz.transition 2018, 3, :o2, 1522360800
            tz.transition 2018, 10, :o1, 1540504800
            tz.transition 2019, 3, :o2, 1553810400
            tz.transition 2019, 10, :o1, 1571954400
            tz.transition 2020, 3, :o2, 1585260000
            tz.transition 2020, 10, :o1, 1604008800
            tz.transition 2021, 3, :o2, 1616709600
            tz.transition 2021, 10, :o1, 1635458400
            tz.transition 2022, 2, :o2, 1645740000
            tz.transition 2022, 10, :o3, 1666908000
          end
        end
      end
    end
  end
end
