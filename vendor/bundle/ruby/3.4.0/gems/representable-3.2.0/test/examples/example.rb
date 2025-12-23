require 'bundler'
Bundler.setup

require 'representable/yaml'
require 'ostruct'

def reset_representer(*module_name)
  module_name.each do |mod|
    mod.module_eval do
      @representable_attrs = nil
    end
  end
end

class Song < OpenStruct
end

song = Song.new(:title => "Fallout", :track => 1)

module SongRepresenter
  include Representable::JSON

  property :title
  property :track
end

puts song.extend(SongRepresenter).to_json

rox = Song.new.extend(SongRepresenter).from_json(%{ {"title":"Roxanne"} })
puts rox.inspect

module SongRepresenter
  include Representable::JSON

  self.representation_wrap= :hit

  property :title
  property :track
end

puts song.extend(SongRepresenter).to_json



######### collections

reset_representer(SongRepresenter)

module SongRepresenter
  include Representable::JSON

  property :title
  property :track
  collection :composers
end


song = Song.new(:title => "Fallout", :composers => ["Stewart Copeland", "Sting"])
puts song.extend(SongRepresenter).to_json


######### nesting types

class Album < OpenStruct
  def name
    puts @table.inspect
    #@attributes
    @table[:name]
  end
end

module AlbumRepresenter
  include Representable::JSON

  property :name
  property :song, :extend => SongRepresenter, :class => Song
end

album = Album.new(:name => "The Police", :song => song)
puts album.extend(AlbumRepresenter).to_json

reset_representer(AlbumRepresenter)

module AlbumRepresenter
  include Representable::JSON

  property :name
  collection :songs, :extend => SongRepresenter, :class => Song
end

album = Album.new(:name => "The Police", :songs => [song, Song.new(:title => "Synchronicity")])
puts album.extend(AlbumRepresenter).to_json


album = Album.new.extend(AlbumRepresenter).from_json(%{{"name":"Offspring","songs":[{"title":"Genocide"},{"title":"Nitro","composers":["Offspring"]}]}
})
puts album.inspect

reset_representer(SongRepresenter)

######### using helpers (customizing the rendering/parsing) 
module AlbumRepresenter
  include Representable::JSON

  def name
    super.upcase
  end
end

puts Album.new(:name => "The Police").
  extend(AlbumRepresenter).to_json

reset_representer(SongRepresenter)


######### inheritance
module SongRepresenter
  include Representable::JSON

  property :title
  property :track
end

module CoverSongRepresenter
  include Representable::JSON
  include SongRepresenter

  property :covered_by
end


song = Song.new(:title => "Truth Hits Everybody", :covered_by => "No Use For A Name")
puts song.extend(CoverSongRepresenter).to_json


### XML
require 'representable/xml'
module SongRepresenter
  include Representable::XML

  property :title
  property :track
  collection :composers
end
song = Song.new(:title => "Fallout", :composers => ["Stewart Copeland", "Sting"])
puts song.extend(SongRepresenter).to_xml

reset_representer(SongRepresenter)


### YAML
require 'representable/yaml'
module SongRepresenter
  include Representable::YAML

  property :title
  property :track
  collection :composers
end
puts song.extend(SongRepresenter).to_yaml


SongRepresenter.module_eval do
  @representable_attrs = nil
end


### YAML
module SongRepresenter
  include Representable::YAML

  property :title
  property :track
  collection :composers, :style => :flow
end
puts song.extend(SongRepresenter).to_yaml

SongRepresenter.module_eval do
  @representable_attrs = nil
end

# R/W support
song = Song.new(:title => "You're Wrong", :track => 4)
module SongRepresenter
  include Representable::Hash

  property :title, :readable => false
  property :track
end
puts song.extend(SongRepresenter).to_hash

SongRepresenter.module_eval do
  @representable_attrs = nil
end

module SongRepresenter
  include Representable::Hash

  property :title, :writeable => false
  property :track
end
song = Song.new.extend(SongRepresenter)
song.from_hash({:title => "Fallout", :track => 1})
puts song

######### custom methods in representer (using helpers)
######### conditions
######### :as
######### XML::Collection
######### polymorphic :extend and :class, instance context!, :instance
class CoverSong < Song
end

songs = [Song.new(title: "Weirdo", track: 5), CoverSong.new(title: "Truth Hits Everybody", track: 6, copyright: "The Police")]
album = Album.new(name: "Incognito", songs: songs)


reset_representer(SongRepresenter, AlbumRepresenter)

module SongRepresenter
  include Representable::Hash

  property :title
  property :track
end

module CoverSongRepresenter
  include Representable::Hash
  include SongRepresenter

  property :copyright
end

module AlbumRepresenter
  include Representable::Hash

  property :name
  collection :songs, :extend => lambda { |song| song.is_a?(CoverSong) ? CoverSongRepresenter : SongRepresenter }
end

puts album.extend(AlbumRepresenter).to_hash

reset_representer(AlbumRepresenter)

module AlbumRepresenter
  include Representable::Hash

  property :name
  collection :songs, 
    :extend => lambda { |song| song.is_a?(CoverSong) ? CoverSongRepresenter : SongRepresenter },
    :class  => lambda { |hsh| hsh.has_key?("copyright") ? CoverSong : Song } #=> {"title"=>"Weirdo", "track"=>5}
end

album = Album.new.extend(AlbumRepresenter).from_hash({"name"=>"Incognito", "songs"=>[{"title"=>"Weirdo", "track"=>5}, {"title"=>"Truth Hits Everybody", "track"=>6, "copyright"=>"The Police"}]})
puts album.inspect

reset_representer(AlbumRepresenter)

module AlbumRepresenter
  include Representable::Hash

  property :name
  collection :songs, 
    :extend   => lambda { |song| song.is_a?(CoverSong) ? CoverSongRepresenter : SongRepresenter },
    :instance => lambda { |hsh| hsh.has_key?("copyright") ? CoverSong.new : Song.new(original: true) }
end

album = Album.new.extend(AlbumRepresenter).from_hash({"name"=>"Incognito", "songs"=>[{"title"=>"Weirdo", "track"=>5}, {"title"=>"Truth Hits Everybody", "track"=>6, "copyright"=>"The Police"}]})
puts album.inspect

######### #hash

reset_representer(SongRepresenter)

module SongRepresenter
  include Representable::JSON

  property :title
  hash :ratings
end

puts Song.new(title: "Bliss", ratings: {"Rolling Stone" => 4.9, "FryZine" => 4.5}).extend(SongRepresenter).to_json

######### JSON::Hash

module FavoriteSongsRepresenter
  include Representable::JSON::Hash
end

puts( {"Nick" => "Hyper Music", "El" => "Blown In The Wind"}.extend(FavoriteSongsRepresenter).to_json)

require 'representable/json/hash'
module FavoriteSongsRepresenter
  include Representable::JSON::Hash

  values extend: SongRepresenter, class: Song
end

puts( {"Nick" => Song.new(title: "Hyper Music")}.extend(FavoriteSongsRepresenter).to_json)


require 'representable/json/collection'
module SongsRepresenter
  include Representable::JSON::Collection

  items extend: SongRepresenter, class: Song
end

puts [Song.new(title: "Hyper Music"), Song.new(title: "Screenager")].extend(SongsRepresenter).to_json
