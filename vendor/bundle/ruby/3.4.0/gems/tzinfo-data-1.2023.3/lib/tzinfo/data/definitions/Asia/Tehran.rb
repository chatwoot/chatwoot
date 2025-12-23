# encoding: UTF-8

# This file contains data derived from the IANA Time Zone Database
# (https://www.iana.org/time-zones).

module TZInfo
  module Data
    module Definitions
      module Asia
        module Tehran
          include TimezoneDefinition
          
          timezone 'Asia/Tehran' do |tz|
            tz.offset :o0, 12344, 0, :LMT
            tz.offset :o1, 12344, 0, :TMT
            tz.offset :o2, 12600, 0, :'+0330'
            tz.offset :o3, 12600, 3600, :'+0430'
            tz.offset :o4, 14400, 0, :'+04'
            tz.offset :o5, 14400, 3600, :'+05'
            
            tz.transition 1915, 12, :o1, -1704165944, 26145324257, 10800
            tz.transition 1935, 6, :o2, -1090466744, 26222036657, 10800
            tz.transition 1977, 3, :o3, 227820600
            tz.transition 1977, 10, :o4, 246223800
            tz.transition 1978, 3, :o5, 259617600
            tz.transition 1978, 8, :o4, 271108800
            tz.transition 1978, 12, :o2, 283982400
            tz.transition 1979, 5, :o3, 296598600
            tz.transition 1979, 9, :o2, 306531000
            tz.transition 1980, 3, :o3, 322432200
            tz.transition 1980, 9, :o2, 338499000
            tz.transition 1991, 5, :o3, 673216200
            tz.transition 1991, 9, :o2, 685481400
            tz.transition 1992, 3, :o3, 701209800
            tz.transition 1992, 9, :o2, 717103800
            tz.transition 1993, 3, :o3, 732745800
            tz.transition 1993, 9, :o2, 748639800
            tz.transition 1994, 3, :o3, 764281800
            tz.transition 1994, 9, :o2, 780175800
            tz.transition 1995, 3, :o3, 795817800
            tz.transition 1995, 9, :o2, 811711800
            tz.transition 1996, 3, :o3, 827353800
            tz.transition 1996, 9, :o2, 843247800
            tz.transition 1997, 3, :o3, 858976200
            tz.transition 1997, 9, :o2, 874870200
            tz.transition 1998, 3, :o3, 890512200
            tz.transition 1998, 9, :o2, 906406200
            tz.transition 1999, 3, :o3, 922048200
            tz.transition 1999, 9, :o2, 937942200
            tz.transition 2000, 3, :o3, 953584200
            tz.transition 2000, 9, :o2, 969478200
            tz.transition 2001, 3, :o3, 985206600
            tz.transition 2001, 9, :o2, 1001100600
            tz.transition 2002, 3, :o3, 1016742600
            tz.transition 2002, 9, :o2, 1032636600
            tz.transition 2003, 3, :o3, 1048278600
            tz.transition 2003, 9, :o2, 1064172600
            tz.transition 2004, 3, :o3, 1079814600
            tz.transition 2004, 9, :o2, 1095708600
            tz.transition 2005, 3, :o3, 1111437000
            tz.transition 2005, 9, :o2, 1127331000
            tz.transition 2008, 3, :o3, 1206045000
            tz.transition 2008, 9, :o2, 1221939000
            tz.transition 2009, 3, :o3, 1237667400
            tz.transition 2009, 9, :o2, 1253561400
            tz.transition 2010, 3, :o3, 1269203400
            tz.transition 2010, 9, :o2, 1285097400
            tz.transition 2011, 3, :o3, 1300739400
            tz.transition 2011, 9, :o2, 1316633400
            tz.transition 2012, 3, :o3, 1332275400
            tz.transition 2012, 9, :o2, 1348169400
            tz.transition 2013, 3, :o3, 1363897800
            tz.transition 2013, 9, :o2, 1379791800
            tz.transition 2014, 3, :o3, 1395433800
            tz.transition 2014, 9, :o2, 1411327800
            tz.transition 2015, 3, :o3, 1426969800
            tz.transition 2015, 9, :o2, 1442863800
            tz.transition 2016, 3, :o3, 1458505800
            tz.transition 2016, 9, :o2, 1474399800
            tz.transition 2017, 3, :o3, 1490128200
            tz.transition 2017, 9, :o2, 1506022200
            tz.transition 2018, 3, :o3, 1521664200
            tz.transition 2018, 9, :o2, 1537558200
            tz.transition 2019, 3, :o3, 1553200200
            tz.transition 2019, 9, :o2, 1569094200
            tz.transition 2020, 3, :o3, 1584736200
            tz.transition 2020, 9, :o2, 1600630200
            tz.transition 2021, 3, :o3, 1616358600
            tz.transition 2021, 9, :o2, 1632252600
            tz.transition 2022, 3, :o3, 1647894600
            tz.transition 2022, 9, :o2, 1663788600
          end
        end
      end
    end
  end
end
