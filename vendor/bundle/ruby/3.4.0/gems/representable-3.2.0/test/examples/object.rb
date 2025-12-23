require "test_helper"

require "ostruct"
require "pp"


source = OpenStruct.new(name: "30 Years Live", songs: [
  OpenStruct.new(id: 1, title: "Dear Beloved"), OpenStruct.new(id: 2, title: "Fuck Armageddon")])

require "representable/object"

class AlbumRepresenter < Representable::Decorator
  include Representable::Object

  property :name
  collection :songs, instance: ->(fragment, *) { Song.new } do
    property :title
  end
end


Album = Struct.new(:name, :songs)
Song = Struct.new(:title)

target = Album.new

AlbumRepresenter.new(target).from_object(source)