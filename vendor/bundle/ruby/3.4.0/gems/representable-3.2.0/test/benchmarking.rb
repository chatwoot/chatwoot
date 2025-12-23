require 'test_helper'
require 'benchmark'

SONG_PROPERTIES = 1000.times.collect do |i|
  "property_#{i}"
end


module SongRepresenter
  include Representable::JSON

  SONG_PROPERTIES.each { |p| property p }
end

class SongDecorator < Representable::Decorator
  include Representable::JSON

  SONG_PROPERTIES.each { |p| property p }
end

module AlbumRepresenter
  include Representable::JSON

  # collection :songs, extend: SongRepresenter
  collection :songs, extend: SongDecorator
end

def random_song
  attrs = Hash[SONG_PROPERTIES.collect { |n| [n,n] }]
  OpenStruct.new(attrs)
end

times = []

3.times.each do
  album = OpenStruct.new(songs: 100.times.collect { random_song })

  times << Benchmark.measure do
    puts "================ next!"
    album.extend(AlbumRepresenter).to_json
  end
end

puts times.join("")

# 100 songs, 100 attrs
#  0.050000   0.000000   0.050000 (  0.093157)

## 100 songs, 1000 attrs
#  0.470000   0.010000   0.480000 (  0.483708)


### without binding cache:
  # 2.790000   0.030000   2.820000 (  2.820190)



### with extend: on Song, with binding cache>
  # 2.490000   0.030000   2.520000 (  2.517433) 2.4-3.0
  ### without skip?
  # 2.030000   0.020000   2.050000 (  2.050796) 2.1-2.3

    ### without :writer
    # 2.270000   0.010000   2.280000 (  2.284530 1.9-2.2
      ### without :render_filter
      #   2.020000   0.000000   2.020000 (  2.030234) 1.5-2.0
        ###without default_for and skipable?
        #   1.730000   0.010000   1.740000 (  1.735597 1.4-1.7
          ### without :serialize
          #   1.780000   0.010000   1.790000 (  1.786791) 1.4-1.7
          ### using decorator
          # 1.400000   0.030000   1.430000 (  1.434206) 1.4-1.6
            ### with prepare AFTER  representable?
            # 1.330000   0.010000   1.340000 (  1.335900) 1.1-1.3


# representable 2.0
# 3.000000   0.020000   3.020000 (  3.013031) 2.7-3.0

# no method missing
# 2.280000   0.030000   2.310000 (  2.313522) 2.2-2.5
# no def_delegator in Definition
# 2.130000   0.010000   2.140000 (  2.136115) 1.7-2.1
