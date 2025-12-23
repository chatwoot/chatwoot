# encoding: UTF-8

# This file contains data derived from the IANA Time Zone Database
# (https://www.iana.org/time-zones).

module TZInfo
  module Data
    module Definitions
      module Pacific
        module Norfolk
          include TimezoneDefinition
          
          timezone 'Pacific/Norfolk' do |tz|
            tz.offset :o0, 40312, 0, :LMT
            tz.offset :o1, 40320, 0, :'+1112'
            tz.offset :o2, 41400, 0, :'+1130'
            tz.offset :o3, 41400, 3600, :'+1230'
            tz.offset :o4, 39600, 0, :'+11'
            tz.offset :o5, 39600, 3600, :'+12'
            
            tz.transition 1900, 12, :o1, -2177493112, 26086158361, 10800
            tz.transition 1950, 12, :o2, -599656320, 73009411, 30
            tz.transition 1974, 10, :o3, 152029800
            tz.transition 1975, 3, :o2, 162916200
            tz.transition 2015, 10, :o4, 1443882600
            tz.transition 2019, 10, :o5, 1570287600
            tz.transition 2020, 4, :o4, 1586012400
            tz.transition 2020, 10, :o5, 1601737200
            tz.transition 2021, 4, :o4, 1617462000
            tz.transition 2021, 10, :o5, 1633186800
            tz.transition 2022, 4, :o4, 1648911600
            tz.transition 2022, 10, :o5, 1664636400
            tz.transition 2023, 4, :o4, 1680361200
            tz.transition 2023, 9, :o5, 1696086000
            tz.transition 2024, 4, :o4, 1712415600
            tz.transition 2024, 10, :o5, 1728140400
            tz.transition 2025, 4, :o4, 1743865200
            tz.transition 2025, 10, :o5, 1759590000
            tz.transition 2026, 4, :o4, 1775314800
            tz.transition 2026, 10, :o5, 1791039600
            tz.transition 2027, 4, :o4, 1806764400
            tz.transition 2027, 10, :o5, 1822489200
            tz.transition 2028, 4, :o4, 1838214000
            tz.transition 2028, 9, :o5, 1853938800
            tz.transition 2029, 3, :o4, 1869663600
            tz.transition 2029, 10, :o5, 1885993200
            tz.transition 2030, 4, :o4, 1901718000
            tz.transition 2030, 10, :o5, 1917442800
            tz.transition 2031, 4, :o4, 1933167600
            tz.transition 2031, 10, :o5, 1948892400
            tz.transition 2032, 4, :o4, 1964617200
            tz.transition 2032, 10, :o5, 1980342000
            tz.transition 2033, 4, :o4, 1996066800
            tz.transition 2033, 10, :o5, 2011791600
            tz.transition 2034, 4, :o4, 2027516400
            tz.transition 2034, 9, :o5, 2043241200
            tz.transition 2035, 3, :o4, 2058966000
            tz.transition 2035, 10, :o5, 2075295600
            tz.transition 2036, 4, :o4, 2091020400
            tz.transition 2036, 10, :o5, 2106745200
            tz.transition 2037, 4, :o4, 2122470000
            tz.transition 2037, 10, :o5, 2138194800
            tz.transition 2038, 4, :o4, 2153919600, 19724137, 8
            tz.transition 2038, 10, :o5, 2169644400, 19725593, 8
            tz.transition 2039, 4, :o4, 2185369200, 19727049, 8
            tz.transition 2039, 10, :o5, 2201094000, 19728505, 8
            tz.transition 2040, 3, :o4, 2216818800, 19729961, 8
            tz.transition 2040, 10, :o5, 2233148400, 19731473, 8
            tz.transition 2041, 4, :o4, 2248873200, 19732929, 8
            tz.transition 2041, 10, :o5, 2264598000, 19734385, 8
            tz.transition 2042, 4, :o4, 2280322800, 19735841, 8
            tz.transition 2042, 10, :o5, 2296047600, 19737297, 8
            tz.transition 2043, 4, :o4, 2311772400, 19738753, 8
            tz.transition 2043, 10, :o5, 2327497200, 19740209, 8
            tz.transition 2044, 4, :o4, 2343222000, 19741665, 8
            tz.transition 2044, 10, :o5, 2358946800, 19743121, 8
            tz.transition 2045, 4, :o4, 2374671600, 19744577, 8
            tz.transition 2045, 9, :o5, 2390396400, 19746033, 8
            tz.transition 2046, 3, :o4, 2406121200, 19747489, 8
            tz.transition 2046, 10, :o5, 2422450800, 19749001, 8
            tz.transition 2047, 4, :o4, 2438175600, 19750457, 8
            tz.transition 2047, 10, :o5, 2453900400, 19751913, 8
            tz.transition 2048, 4, :o4, 2469625200, 19753369, 8
            tz.transition 2048, 10, :o5, 2485350000, 19754825, 8
            tz.transition 2049, 4, :o4, 2501074800, 19756281, 8
            tz.transition 2049, 10, :o5, 2516799600, 19757737, 8
            tz.transition 2050, 4, :o4, 2532524400, 19759193, 8
            tz.transition 2050, 10, :o5, 2548249200, 19760649, 8
            tz.transition 2051, 4, :o4, 2563974000, 19762105, 8
            tz.transition 2051, 9, :o5, 2579698800, 19763561, 8
            tz.transition 2052, 4, :o4, 2596028400, 19765073, 8
            tz.transition 2052, 10, :o5, 2611753200, 19766529, 8
            tz.transition 2053, 4, :o4, 2627478000, 19767985, 8
            tz.transition 2053, 10, :o5, 2643202800, 19769441, 8
            tz.transition 2054, 4, :o4, 2658927600, 19770897, 8
            tz.transition 2054, 10, :o5, 2674652400, 19772353, 8
            tz.transition 2055, 4, :o4, 2690377200, 19773809, 8
            tz.transition 2055, 10, :o5, 2706102000, 19775265, 8
            tz.transition 2056, 4, :o4, 2721826800, 19776721, 8
            tz.transition 2056, 9, :o5, 2737551600, 19778177, 8
            tz.transition 2057, 3, :o4, 2753276400, 19779633, 8
            tz.transition 2057, 10, :o5, 2769606000, 19781145, 8
            tz.transition 2058, 4, :o4, 2785330800, 19782601, 8
            tz.transition 2058, 10, :o5, 2801055600, 19784057, 8
            tz.transition 2059, 4, :o4, 2816780400, 19785513, 8
            tz.transition 2059, 10, :o5, 2832505200, 19786969, 8
            tz.transition 2060, 4, :o4, 2848230000, 19788425, 8
            tz.transition 2060, 10, :o5, 2863954800, 19789881, 8
            tz.transition 2061, 4, :o4, 2879679600, 19791337, 8
            tz.transition 2061, 10, :o5, 2895404400, 19792793, 8
            tz.transition 2062, 4, :o4, 2911129200, 19794249, 8
            tz.transition 2062, 9, :o5, 2926854000, 19795705, 8
            tz.transition 2063, 3, :o4, 2942578800, 19797161, 8
            tz.transition 2063, 10, :o5, 2958908400, 19798673, 8
            tz.transition 2064, 4, :o4, 2974633200, 19800129, 8
            tz.transition 2064, 10, :o5, 2990358000, 19801585, 8
            tz.transition 2065, 4, :o4, 3006082800, 19803041, 8
            tz.transition 2065, 10, :o5, 3021807600, 19804497, 8
            tz.transition 2066, 4, :o4, 3037532400, 19805953, 8
            tz.transition 2066, 10, :o5, 3053257200, 19807409, 8
            tz.transition 2067, 4, :o4, 3068982000, 19808865, 8
            tz.transition 2067, 10, :o5, 3084706800, 19810321, 8
            tz.transition 2068, 3, :o4, 3100431600, 19811777, 8
            tz.transition 2068, 10, :o5, 3116761200, 19813289, 8
            tz.transition 2069, 4, :o4, 3132486000, 19814745, 8
            tz.transition 2069, 10, :o5, 3148210800, 19816201, 8
            tz.transition 2070, 4, :o4, 3163935600, 19817657, 8
            tz.transition 2070, 10, :o5, 3179660400, 19819113, 8
            tz.transition 2071, 4, :o4, 3195385200, 19820569, 8
            tz.transition 2071, 10, :o5, 3211110000, 19822025, 8
            tz.transition 2072, 4, :o4, 3226834800, 19823481, 8
            tz.transition 2072, 10, :o5, 3242559600, 19824937, 8
            tz.transition 2073, 4, :o4, 3258284400, 19826393, 8
          end
        end
      end
    end
  end
end
