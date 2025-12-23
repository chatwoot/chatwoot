# encoding: UTF-8

# This file contains data derived from the IANA Time Zone Database
# (https://www.iana.org/time-zones).

module TZInfo
  module Data
    module Definitions
      module Asia
        module Hong_Kong
          include TimezoneDefinition
          
          timezone 'Asia/Hong_Kong' do |tz|
            tz.offset :o0, 27402, 0, :LMT
            tz.offset :o1, 28800, 0, :HKT
            tz.offset :o2, 28800, 3600, :HKST
            tz.offset :o3, 28800, 1800, :HKWT
            tz.offset :o4, 32400, 0, :JST
            
            tz.transition 1904, 10, :o1, -2056690800, 58002797, 24
            tz.transition 1941, 6, :o2, -900910800, 58323847, 24
            tz.transition 1941, 9, :o3, -891579600, 58326439, 24
            tz.transition 1941, 12, :o4, -884248200, 116656951, 48
            tz.transition 1945, 11, :o1, -761209200, 58362653, 24
            tz.transition 1946, 4, :o2, -747907200, 14591587, 6
            tz.transition 1946, 11, :o1, -728541000, 38914485, 16
            tz.transition 1947, 4, :o2, -717049800, 38916613, 16
            tz.transition 1947, 11, :o1, -697091400, 38920309, 16
            tz.transition 1948, 5, :o2, -683785800, 38922773, 16
            tz.transition 1948, 10, :o1, -668061000, 38925685, 16
            tz.transition 1949, 4, :o2, -654755400, 38928149, 16
            tz.transition 1949, 10, :o1, -636611400, 38931509, 16
            tz.transition 1950, 4, :o2, -623305800, 38933973, 16
            tz.transition 1950, 10, :o1, -605161800, 38937333, 16
            tz.transition 1951, 3, :o2, -591856200, 38939797, 16
            tz.transition 1951, 10, :o1, -573712200, 38943157, 16
            tz.transition 1952, 4, :o2, -559801800, 38945733, 16
            tz.transition 1952, 11, :o1, -541657800, 38949093, 16
            tz.transition 1953, 4, :o2, -528352200, 38951557, 16
            tz.transition 1953, 10, :o1, -510211800, 116864749, 48
            tz.transition 1954, 3, :o2, -498112200, 38957157, 16
            tz.transition 1954, 10, :o1, -478762200, 116882221, 48
            tz.transition 1955, 3, :o2, -466662600, 38962981, 16
            tz.transition 1955, 11, :o1, -446707800, 116900029, 48
            tz.transition 1956, 3, :o2, -435213000, 38968805, 16
            tz.transition 1956, 11, :o1, -415258200, 116917501, 48
            tz.transition 1957, 3, :o2, -403158600, 38974741, 16
            tz.transition 1957, 11, :o1, -383808600, 116934973, 48
            tz.transition 1958, 3, :o2, -371709000, 38980565, 16
            tz.transition 1958, 11, :o1, -352359000, 116952445, 48
            tz.transition 1959, 3, :o2, -340259400, 38986389, 16
            tz.transition 1959, 10, :o1, -320909400, 116969917, 48
            tz.transition 1960, 3, :o2, -308809800, 38992213, 16
            tz.transition 1960, 11, :o1, -288855000, 116987725, 48
            tz.transition 1961, 3, :o2, -277360200, 38998037, 16
            tz.transition 1961, 11, :o1, -257405400, 117005197, 48
            tz.transition 1962, 3, :o2, -245910600, 39003861, 16
            tz.transition 1962, 11, :o1, -225955800, 117022669, 48
            tz.transition 1963, 3, :o2, -213856200, 39009797, 16
            tz.transition 1963, 11, :o1, -194506200, 117040141, 48
            tz.transition 1964, 3, :o2, -182406600, 39015621, 16
            tz.transition 1964, 10, :o1, -163056600, 117057613, 48
            tz.transition 1965, 4, :o2, -148537800, 39021893, 16
            tz.transition 1965, 10, :o1, -132816600, 117074413, 48
            tz.transition 1966, 4, :o2, -117088200, 39027717, 16
            tz.transition 1966, 10, :o1, -101367000, 117091885, 48
            tz.transition 1967, 4, :o2, -85638600, 39033541, 16
            tz.transition 1967, 10, :o1, -69312600, 117109693, 48
            tz.transition 1968, 4, :o2, -53584200, 39039477, 16
            tz.transition 1968, 10, :o1, -37863000, 117127165, 48
            tz.transition 1969, 4, :o2, -22134600, 39045301, 16
            tz.transition 1969, 10, :o1, -6413400, 117144637, 48
            tz.transition 1970, 4, :o2, 9315000
            tz.transition 1970, 10, :o1, 25036200
            tz.transition 1971, 4, :o2, 40764600
            tz.transition 1971, 10, :o1, 56485800
            tz.transition 1972, 4, :o2, 72214200
            tz.transition 1972, 10, :o1, 88540200
            tz.transition 1973, 4, :o2, 104268600
            tz.transition 1973, 10, :o1, 119989800
            tz.transition 1973, 12, :o2, 126041400
            tz.transition 1974, 10, :o1, 151439400
            tz.transition 1975, 4, :o2, 167167800
            tz.transition 1975, 10, :o1, 182889000
            tz.transition 1976, 4, :o2, 198617400
            tz.transition 1976, 10, :o1, 214338600
            tz.transition 1979, 5, :o2, 295385400
            tz.transition 1979, 10, :o1, 309292200
          end
        end
      end
    end
  end
end
