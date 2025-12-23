# encoding: UTF-8

# This file contains data derived from the IANA Time Zone Database
# (https://www.iana.org/time-zones).

module TZInfo
  module Data
    module Definitions
      module America
        module Campo_Grande
          include TimezoneDefinition
          
          timezone 'America/Campo_Grande' do |tz|
            tz.offset :o0, -13108, 0, :LMT
            tz.offset :o1, -14400, 0, :'-04'
            tz.offset :o2, -14400, 3600, :'-03'
            
            tz.transition 1914, 1, :o1, -1767212492, 52274886877, 21600
            tz.transition 1931, 10, :o2, -1206954000, 19412945, 8
            tz.transition 1932, 4, :o1, -1191358800, 19414389, 8
            tz.transition 1932, 10, :o2, -1175371200, 7280951, 3
            tz.transition 1933, 4, :o1, -1159822800, 19417309, 8
            tz.transition 1949, 12, :o2, -633816000, 7299755, 3
            tz.transition 1950, 4, :o1, -622065600, 7300163, 3
            tz.transition 1950, 12, :o2, -602280000, 7300850, 3
            tz.transition 1951, 4, :o1, -591829200, 19469901, 8
            tz.transition 1951, 12, :o2, -570744000, 7301945, 3
            tz.transition 1952, 4, :o1, -560206800, 19472829, 8
            tz.transition 1952, 12, :o2, -539121600, 7303043, 3
            tz.transition 1953, 3, :o1, -531349200, 19475501, 8
            tz.transition 1963, 12, :o2, -191361600, 7315118, 3
            tz.transition 1964, 3, :o1, -184194000, 19507645, 8
            tz.transition 1965, 1, :o2, -155160000, 7316375, 3
            tz.transition 1965, 3, :o1, -150066000, 19510805, 8
            tz.transition 1965, 12, :o2, -128894400, 7317287, 3
            tz.transition 1966, 3, :o1, -121122000, 19513485, 8
            tz.transition 1966, 11, :o2, -99950400, 7318292, 3
            tz.transition 1967, 3, :o1, -89586000, 19516405, 8
            tz.transition 1967, 11, :o2, -68414400, 7319387, 3
            tz.transition 1968, 3, :o1, -57963600, 19519333, 8
            tz.transition 1985, 11, :o2, 499752000
            tz.transition 1986, 3, :o1, 511239600
            tz.transition 1986, 10, :o2, 530596800
            tz.transition 1987, 2, :o1, 540270000
            tz.transition 1987, 10, :o2, 562132800
            tz.transition 1988, 2, :o1, 571201200
            tz.transition 1988, 10, :o2, 592977600
            tz.transition 1989, 1, :o1, 602046000
            tz.transition 1989, 10, :o2, 624427200
            tz.transition 1990, 2, :o1, 634705200
            tz.transition 1990, 10, :o2, 656481600
            tz.transition 1991, 2, :o1, 666759600
            tz.transition 1991, 10, :o2, 687931200
            tz.transition 1992, 2, :o1, 697604400
            tz.transition 1992, 10, :o2, 719985600
            tz.transition 1993, 1, :o1, 728449200
            tz.transition 1993, 10, :o2, 750830400
            tz.transition 1994, 2, :o1, 761713200
            tz.transition 1994, 10, :o2, 782280000
            tz.transition 1995, 2, :o1, 793162800
            tz.transition 1995, 10, :o2, 813729600
            tz.transition 1996, 2, :o1, 824007600
            tz.transition 1996, 10, :o2, 844574400
            tz.transition 1997, 2, :o1, 856062000
            tz.transition 1997, 10, :o2, 876110400
            tz.transition 1998, 3, :o1, 888721200
            tz.transition 1998, 10, :o2, 908078400
            tz.transition 1999, 2, :o1, 919566000
            tz.transition 1999, 10, :o2, 938923200
            tz.transition 2000, 2, :o1, 951620400
            tz.transition 2000, 10, :o2, 970977600
            tz.transition 2001, 2, :o1, 982465200
            tz.transition 2001, 10, :o2, 1003032000
            tz.transition 2002, 2, :o1, 1013914800
            tz.transition 2002, 11, :o2, 1036296000
            tz.transition 2003, 2, :o1, 1045364400
            tz.transition 2003, 10, :o2, 1066536000
            tz.transition 2004, 2, :o1, 1076814000
            tz.transition 2004, 11, :o2, 1099368000
            tz.transition 2005, 2, :o1, 1108868400
            tz.transition 2005, 10, :o2, 1129435200
            tz.transition 2006, 2, :o1, 1140318000
            tz.transition 2006, 11, :o2, 1162699200
            tz.transition 2007, 2, :o1, 1172372400
            tz.transition 2007, 10, :o2, 1192334400
            tz.transition 2008, 2, :o1, 1203217200
            tz.transition 2008, 10, :o2, 1224388800
            tz.transition 2009, 2, :o1, 1234666800
            tz.transition 2009, 10, :o2, 1255838400
            tz.transition 2010, 2, :o1, 1266721200
            tz.transition 2010, 10, :o2, 1287288000
            tz.transition 2011, 2, :o1, 1298170800
            tz.transition 2011, 10, :o2, 1318737600
            tz.transition 2012, 2, :o1, 1330225200
            tz.transition 2012, 10, :o2, 1350792000
            tz.transition 2013, 2, :o1, 1361070000
            tz.transition 2013, 10, :o2, 1382241600
            tz.transition 2014, 2, :o1, 1392519600
            tz.transition 2014, 10, :o2, 1413691200
            tz.transition 2015, 2, :o1, 1424574000
            tz.transition 2015, 10, :o2, 1445140800
            tz.transition 2016, 2, :o1, 1456023600
            tz.transition 2016, 10, :o2, 1476590400
            tz.transition 2017, 2, :o1, 1487473200
            tz.transition 2017, 10, :o2, 1508040000
            tz.transition 2018, 2, :o1, 1518922800
            tz.transition 2018, 11, :o2, 1541304000
            tz.transition 2019, 2, :o1, 1550372400
          end
        end
      end
    end
  end
end
