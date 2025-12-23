# encoding: UTF-8

# This file contains data derived from the IANA Time Zone Database
# (https://www.iana.org/time-zones).

module TZInfo
  module Data
    module Definitions
      module Pacific
        module Palau
          include TimezoneDefinition
          
          timezone 'Pacific/Palau' do |tz|
            tz.offset :o0, -54124, 0, :LMT
            tz.offset :o1, 32276, 0, :LMT
            tz.offset :o2, 32400, 0, :'+09'
            
            tz.transition 1844, 12, :o1, -3944624276, 51730533931, 21600
            tz.transition 1900, 12, :o2, -2177485076, 52172318731, 21600
          end
        end
      end
    end
  end
end
