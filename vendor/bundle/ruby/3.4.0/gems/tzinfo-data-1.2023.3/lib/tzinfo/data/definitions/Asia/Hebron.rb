# encoding: UTF-8

# This file contains data derived from the IANA Time Zone Database
# (https://www.iana.org/time-zones).

module TZInfo
  module Data
    module Definitions
      module Asia
        module Hebron
          include TimezoneDefinition
          
          timezone 'Asia/Hebron' do |tz|
            tz.offset :o0, 8423, 0, :LMT
            tz.offset :o1, 7200, 0, :EET
            tz.offset :o2, 7200, 3600, :EEST
            tz.offset :o3, 7200, 0, :IST
            tz.offset :o4, 7200, 3600, :IDT
            
            tz.transition 1900, 9, :o1, -2185410023, 208681349977, 86400
            tz.transition 1940, 6, :o2, -933638400, 4859563, 2
            tz.transition 1940, 10, :o1, -923097600, 4859807, 2
            tz.transition 1940, 11, :o2, -919036800, 4859901, 2
            tz.transition 1942, 11, :o1, -857347200, 4861329, 2
            tz.transition 1943, 4, :o2, -844300800, 4861631, 2
            tz.transition 1943, 11, :o1, -825811200, 4862059, 2
            tz.transition 1944, 4, :o2, -812678400, 4862363, 2
            tz.transition 1944, 11, :o1, -794188800, 4862791, 2
            tz.transition 1945, 4, :o2, -779846400, 4863123, 2
            tz.transition 1945, 11, :o1, -762652800, 4863521, 2
            tz.transition 1946, 4, :o2, -748310400, 4863853, 2
            tz.transition 1946, 11, :o1, -731116800, 4864251, 2
            tz.transition 1957, 5, :o2, -399088800, 29231621, 12
            tz.transition 1957, 9, :o1, -386650800, 19488899, 8
            tz.transition 1958, 4, :o2, -368330400, 29235893, 12
            tz.transition 1958, 9, :o1, -355114800, 19491819, 8
            tz.transition 1959, 4, :o2, -336790800, 58480547, 24
            tz.transition 1959, 9, :o1, -323654400, 4873683, 2
            tz.transition 1960, 4, :o2, -305168400, 58489331, 24
            tz.transition 1960, 9, :o1, -292032000, 4874415, 2
            tz.transition 1961, 4, :o2, -273632400, 58498091, 24
            tz.transition 1961, 9, :o1, -260496000, 4875145, 2
            tz.transition 1962, 4, :o2, -242096400, 58506851, 24
            tz.transition 1962, 9, :o1, -228960000, 4875875, 2
            tz.transition 1963, 4, :o2, -210560400, 58515611, 24
            tz.transition 1963, 9, :o1, -197424000, 4876605, 2
            tz.transition 1964, 4, :o2, -178938000, 58524395, 24
            tz.transition 1964, 9, :o1, -165801600, 4877337, 2
            tz.transition 1965, 4, :o2, -147402000, 58533155, 24
            tz.transition 1965, 9, :o1, -134265600, 4878067, 2
            tz.transition 1966, 4, :o2, -115866000, 58541915, 24
            tz.transition 1966, 10, :o1, -102643200, 4878799, 2
            tz.transition 1967, 4, :o2, -84330000, 58550675, 24
            tz.transition 1967, 6, :o3, -81313200, 19517171, 8
            tz.transition 1974, 7, :o4, 142380000
            tz.transition 1974, 10, :o3, 150843600
            tz.transition 1975, 4, :o4, 167176800
            tz.transition 1975, 8, :o3, 178664400
            tz.transition 1980, 8, :o4, 334101600
            tz.transition 1980, 9, :o3, 337730400
            tz.transition 1984, 5, :o4, 452642400
            tz.transition 1984, 8, :o3, 462319200
            tz.transition 1985, 4, :o4, 482277600
            tz.transition 1985, 8, :o3, 494370000
            tz.transition 1986, 5, :o4, 516751200
            tz.transition 1986, 9, :o3, 526424400
            tz.transition 1987, 4, :o4, 545436000
            tz.transition 1987, 9, :o3, 558478800
            tz.transition 1988, 4, :o4, 576626400
            tz.transition 1988, 9, :o3, 589323600
            tz.transition 1989, 4, :o4, 609890400
            tz.transition 1989, 9, :o3, 620773200
            tz.transition 1990, 3, :o4, 638316000
            tz.transition 1990, 8, :o3, 651618000
            tz.transition 1991, 3, :o4, 669765600
            tz.transition 1991, 8, :o3, 683672400
            tz.transition 1992, 3, :o4, 701820000
            tz.transition 1992, 9, :o3, 715726800
            tz.transition 1993, 4, :o4, 733701600
            tz.transition 1993, 9, :o3, 747176400
            tz.transition 1994, 3, :o4, 765151200
            tz.transition 1994, 8, :o3, 778021200
            tz.transition 1995, 3, :o4, 796600800
            tz.transition 1995, 9, :o3, 810075600
            tz.transition 1995, 12, :o1, 820447200
            tz.transition 1996, 4, :o2, 828655200
            tz.transition 1996, 9, :o1, 843170400
            tz.transition 1997, 4, :o2, 860104800
            tz.transition 1997, 9, :o1, 874620000
            tz.transition 1998, 4, :o2, 891554400
            tz.transition 1998, 9, :o1, 906069600
            tz.transition 1999, 4, :o2, 924213600
            tz.transition 1999, 10, :o1, 939934800
            tz.transition 2000, 4, :o2, 956268000
            tz.transition 2000, 10, :o1, 971989200
            tz.transition 2001, 4, :o2, 987717600
            tz.transition 2001, 10, :o1, 1003438800
            tz.transition 2002, 4, :o2, 1019167200
            tz.transition 2002, 10, :o1, 1034888400
            tz.transition 2003, 4, :o2, 1050616800
            tz.transition 2003, 10, :o1, 1066338000
            tz.transition 2004, 4, :o2, 1082066400
            tz.transition 2004, 9, :o1, 1096581600
            tz.transition 2005, 4, :o2, 1113516000
            tz.transition 2005, 10, :o1, 1128380400
            tz.transition 2006, 3, :o2, 1143842400
            tz.transition 2006, 9, :o1, 1158872400
            tz.transition 2007, 3, :o2, 1175378400
            tz.transition 2007, 9, :o1, 1189638000
            tz.transition 2008, 3, :o2, 1206655200
            tz.transition 2008, 8, :o1, 1220216400
            tz.transition 2009, 3, :o2, 1238104800
            tz.transition 2009, 9, :o1, 1252015200
            tz.transition 2010, 3, :o2, 1269554400
            tz.transition 2010, 8, :o1, 1281474000
            tz.transition 2011, 3, :o2, 1301608860
            tz.transition 2011, 7, :o1, 1312146000
            tz.transition 2011, 8, :o2, 1314655200
            tz.transition 2011, 9, :o1, 1317330000
            tz.transition 2012, 3, :o2, 1333058400
            tz.transition 2012, 9, :o1, 1348178400
            tz.transition 2013, 3, :o2, 1364508000
            tz.transition 2013, 9, :o1, 1380229200
            tz.transition 2014, 3, :o2, 1395957600
            tz.transition 2014, 10, :o1, 1414098000
            tz.transition 2015, 3, :o2, 1427493600
            tz.transition 2015, 10, :o1, 1445551200
            tz.transition 2016, 3, :o2, 1458946800
            tz.transition 2016, 10, :o1, 1477692000
            tz.transition 2017, 3, :o2, 1490396400
            tz.transition 2017, 10, :o1, 1509141600
            tz.transition 2018, 3, :o2, 1521846000
            tz.transition 2018, 10, :o1, 1540591200
            tz.transition 2019, 3, :o2, 1553810400
            tz.transition 2019, 10, :o1, 1572037200
            tz.transition 2020, 3, :o2, 1585346400
            tz.transition 2020, 10, :o1, 1603490400
            tz.transition 2021, 3, :o2, 1616796000
            tz.transition 2021, 10, :o1, 1635458400
            tz.transition 2022, 3, :o2, 1648332000
            tz.transition 2022, 10, :o1, 1666998000
            tz.transition 2023, 4, :o2, 1682726400
            tz.transition 2023, 10, :o1, 1698447600
            tz.transition 2024, 4, :o2, 1712966400
            tz.transition 2024, 10, :o1, 1729897200
            tz.transition 2025, 4, :o2, 1743811200
            tz.transition 2025, 10, :o1, 1761346800
            tz.transition 2026, 3, :o2, 1774656000
            tz.transition 2026, 10, :o1, 1792796400
            tz.transition 2027, 3, :o2, 1806105600
            tz.transition 2027, 10, :o1, 1824850800
            tz.transition 2028, 3, :o2, 1837555200
            tz.transition 2028, 10, :o1, 1856300400
            tz.transition 2029, 3, :o2, 1869004800
            tz.transition 2029, 10, :o1, 1887750000
            tz.transition 2030, 3, :o2, 1901059200
            tz.transition 2030, 10, :o1, 1919199600
            tz.transition 2031, 3, :o2, 1932508800
            tz.transition 2031, 10, :o1, 1950649200
            tz.transition 2032, 3, :o2, 1963958400
            tz.transition 2032, 10, :o1, 1982703600
            tz.transition 2033, 3, :o2, 1995408000
            tz.transition 2033, 10, :o1, 2014153200
            tz.transition 2034, 3, :o2, 2026857600
            tz.transition 2034, 10, :o1, 2045602800
            tz.transition 2035, 3, :o2, 2058307200
            tz.transition 2035, 10, :o1, 2077052400
            tz.transition 2036, 3, :o2, 2090361600
            tz.transition 2036, 10, :o1, 2107897200
            tz.transition 2037, 3, :o2, 2121811200
            tz.transition 2037, 10, :o1, 2138742000
            tz.transition 2038, 3, :o2, 2153260800, 4931019, 2
            tz.transition 2038, 9, :o1, 2168982000, 59176595, 24
            tz.transition 2039, 3, :o2, 2184710400, 4931747, 2
            tz.transition 2039, 9, :o1, 2199826800, 59185163, 24
            tz.transition 2039, 10, :o2, 2202854400, 4932167, 2
            tz.transition 2039, 10, :o1, 2203455600, 59186171, 24
            tz.transition 2040, 3, :o2, 2216160000, 4932475, 2
            tz.transition 2040, 8, :o1, 2230066800, 59193563, 24
            tz.transition 2040, 10, :o2, 2233699200, 4932881, 2
            tz.transition 2040, 10, :o1, 2234905200, 59194907, 24
            tz.transition 2041, 3, :o2, 2248214400, 4933217, 2
            tz.transition 2041, 8, :o1, 2260911600, 59202131, 24
            tz.transition 2041, 9, :o2, 2263939200, 4933581, 2
            tz.transition 2041, 10, :o1, 2266354800, 59203643, 24
            tz.transition 2042, 3, :o2, 2279664000, 4933945, 2
            tz.transition 2042, 8, :o1, 2291756400, 59210699, 24
            tz.transition 2042, 9, :o2, 2294784000, 4934295, 2
            tz.transition 2042, 10, :o1, 2297804400, 59212379, 24
            tz.transition 2043, 3, :o2, 2311113600, 4934673, 2
            tz.transition 2043, 7, :o1, 2321996400, 59219099, 24
            tz.transition 2043, 9, :o2, 2325628800, 4935009, 2
            tz.transition 2043, 10, :o1, 2329254000, 59221115, 24
            tz.transition 2044, 3, :o2, 2342563200, 4935401, 2
            tz.transition 2044, 7, :o1, 2352841200, 59227667, 24
            tz.transition 2044, 8, :o2, 2355868800, 4935709, 2
            tz.transition 2044, 10, :o1, 2361308400, 59230019, 24
            tz.transition 2045, 3, :o2, 2374012800, 4936129, 2
            tz.transition 2045, 7, :o1, 2383686000, 59236235, 24
            tz.transition 2045, 8, :o2, 2386713600, 4936423, 2
            tz.transition 2045, 10, :o1, 2392758000, 59238755, 24
            tz.transition 2046, 3, :o2, 2405462400, 4936857, 2
            tz.transition 2046, 6, :o1, 2413926000, 59244635, 24
            tz.transition 2046, 8, :o2, 2417558400, 4937137, 2
            tz.transition 2046, 10, :o1, 2424207600, 59247491, 24
            tz.transition 2047, 3, :o2, 2437516800, 4937599, 2
            tz.transition 2047, 6, :o1, 2444770800, 59253203, 24
            tz.transition 2047, 7, :o2, 2447798400, 4937837, 2
            tz.transition 2047, 10, :o1, 2455657200, 59256227, 24
            tz.transition 2048, 3, :o2, 2468966400, 4938327, 2
            tz.transition 2048, 6, :o1, 2475010800, 59261603, 24
            tz.transition 2048, 7, :o2, 2478643200, 4938551, 2
            tz.transition 2048, 10, :o1, 2487106800, 59264963, 24
            tz.transition 2049, 3, :o2, 2500416000, 4939055, 2
            tz.transition 2049, 5, :o1, 2505855600, 59270171, 24
            tz.transition 2049, 7, :o2, 2508883200, 4939251, 2
            tz.transition 2049, 10, :o1, 2519161200, 59273867, 24
            tz.transition 2050, 3, :o2, 2531865600, 4939783, 2
            tz.transition 2050, 5, :o1, 2536700400, 59278739, 24
            tz.transition 2050, 6, :o2, 2539728000, 4939965, 2
            tz.transition 2050, 10, :o1, 2550610800, 59282603, 24
            tz.transition 2051, 3, :o2, 2563315200, 4940511, 2
            tz.transition 2051, 5, :o1, 2566940400, 59287139, 24
            tz.transition 2051, 6, :o2, 2570572800, 4940679, 2
            tz.transition 2051, 10, :o1, 2582060400, 59291339, 24
            tz.transition 2052, 3, :o2, 2595369600, 4941253, 2
            tz.transition 2052, 4, :o1, 2597785200, 59295707, 24
            tz.transition 2052, 6, :o2, 2600812800, 4941379, 2
            tz.transition 2052, 10, :o1, 2613510000, 59300075, 24
            tz.transition 2053, 3, :o2, 2626819200, 4941981, 2
            tz.transition 2053, 4, :o1, 2628025200, 59304107, 24
            tz.transition 2053, 5, :o2, 2631657600, 4942093, 2
            tz.transition 2053, 10, :o1, 2644959600, 59308811, 24
            tz.transition 2054, 3, :o2, 2658268800, 4942709, 2
            tz.transition 2054, 4, :o1, 2658870000, 59312675, 24
            tz.transition 2054, 5, :o2, 2662502400, 4942807, 2
            tz.transition 2054, 10, :o1, 2676409200, 59317547, 24
            tz.transition 2055, 5, :o2, 2692742400, 4943507, 2
            tz.transition 2055, 10, :o1, 2708463600, 59326451, 24
            tz.transition 2056, 4, :o2, 2723587200, 4944221, 2
            tz.transition 2056, 10, :o1, 2739913200, 59335187, 24
            tz.transition 2057, 4, :o2, 2753827200, 4944921, 2
            tz.transition 2057, 10, :o1, 2771362800, 59343923, 24
            tz.transition 2058, 3, :o2, 2784672000, 4945635, 2
            tz.transition 2058, 10, :o1, 2802812400, 59352659, 24
            tz.transition 2059, 3, :o2, 2816121600, 4946363, 2
            tz.transition 2059, 10, :o1, 2834262000, 59361395, 24
            tz.transition 2060, 3, :o2, 2847571200, 4947091, 2
            tz.transition 2060, 10, :o1, 2866316400, 59370299, 24
            tz.transition 2061, 3, :o2, 2879020800, 4947819, 2
            tz.transition 2061, 10, :o1, 2897766000, 59379035, 24
            tz.transition 2062, 3, :o2, 2910470400, 4948547, 2
            tz.transition 2062, 10, :o1, 2929215600, 59387771, 24
            tz.transition 2063, 3, :o2, 2941920000, 4949275, 2
            tz.transition 2063, 10, :o1, 2960665200, 59396507, 24
            tz.transition 2064, 3, :o2, 2973974400, 4950017, 2
            tz.transition 2064, 10, :o1, 2992114800, 59405243, 24
            tz.transition 2065, 3, :o2, 3005424000, 4950745, 2
            tz.transition 2065, 10, :o1, 3023564400, 59413979, 24
            tz.transition 2066, 3, :o2, 3036873600, 4951473, 2
            tz.transition 2066, 10, :o1, 3055618800, 59422883, 24
            tz.transition 2067, 3, :o2, 3068323200, 4952201, 2
            tz.transition 2067, 10, :o1, 3087068400, 59431619, 24
            tz.transition 2068, 3, :o2, 3099772800, 4952929, 2
            tz.transition 2068, 10, :o1, 3117913200, 59440187, 24
            tz.transition 2069, 3, :o2, 3131827200, 4953671, 2
            tz.transition 2069, 10, :o1, 3148758000, 59448755, 24
            tz.transition 2070, 3, :o2, 3163276800, 4954399, 2
            tz.transition 2070, 10, :o1, 3179602800, 59457323, 24
            tz.transition 2071, 3, :o2, 3194726400, 4955127, 2
            tz.transition 2071, 9, :o1, 3209842800, 59465723, 24
            tz.transition 2072, 3, :o2, 3226176000, 4955855, 2
            tz.transition 2072, 9, :o1, 3240687600, 59474291, 24
            tz.transition 2072, 10, :o2, 3243715200, 4956261, 2
            tz.transition 2073, 9, :o1, 3271532400, 59482859, 24
          end
        end
      end
    end
  end
end
