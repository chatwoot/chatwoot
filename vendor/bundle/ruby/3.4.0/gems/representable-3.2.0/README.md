# Representable

Representable maps Ruby objects to documents and back.

![Build
Status](https://github.com/trailblazer/representable/actions/workflows/ci.yml/badge.svg?branch=master)
[![Gem Version](https://badge.fury.io/rb/representable.svg)](http://badge.fury.io/rb/representable)


In other words: Take an object and decorate it with a representer module. This will allow you to render a JSON, XML or YAML document from that object. But that's only half of it! You can also use representers to parse a document and create or populate an object.

Representable is helpful for all kind of mappings, rendering and parsing workflows. However, it is mostly useful in API code. Are you planning to write a real REST API with representable? Then check out the [Roar](https://github.com/trailblazer/roar) gem first, save work and time and make the world a better place instead.


## Full Documentation

Representable comes with a rich set of options and semantics for parsing and rendering documents. Its [full documentation](https://trailblazer.to/2.1/docs/representable.html) can be found on the Trailblazer site.

## Example

What if we're writing an API for music - songs, albums, bands.

```ruby
class Song < OpenStruct
end

song = Song.new(title: "Fallout", track: 1)
```

## Defining Representations

Representations are defined using representer classes, called _decorator, or modules.

In these examples, let's use decorators

```ruby
class SongRepresenter < Representable::Decorator
  include Representable::JSON

  property :title
  property :track
end
```

In the representer the #property method allows declaring represented attributes of the object. All the representer requires for rendering are readers on the represented object, e.g. `#title` and `#track`. When parsing, it will call setters - in our example, that'd be `#title=` and `#track=`.


## Rendering

Mixing in the representer into the object adds a rendering method.

```ruby
SongRepresenter.new(song).to_json
#=> {"title":"Fallout","track":1}
```

## Parsing

It also adds support for parsing.

```ruby
song = SongRepresenter.new(song).from_json(%{ {"title":"Roxanne"} })
#=> #<Song title="Roxanne", track=nil>
```

Note that parsing hashes per default does [require string keys](https://trailblazer.to/2.1/docs/representable.html#representable-api-symbol-keys) and does _not_ pick up symbol keys.


## Collections

Let's add a list of composers to the song representation.

```ruby
class SongRepresenter < Representable::Decorator
  include Representable::JSON

  property :title
  property :track
  collection :composers
end
```

Surprisingly, `#collection` lets us define lists of objects to represent.

```ruby
Song.new(title: "Fallout", composers: ["Stewart Copeland", "Sting"]).
  extend(SongRepresenter).to_json

#=> {"title":"Fallout","composers":["Stewart Copeland","Sting"]}
```

And again, this works both ways - in addition to the title it extracts the composers from the document, too.


## Nesting

Representers can also manage compositions. Why not use an album that contains a list of songs?

```ruby
class Album < OpenStruct
end

album = Album.new(name: "The Police", songs: [song, Song.new(title: "Synchronicity")])
```

Here comes the representer that defines the composition.

```ruby
class AlbumRepresenter < Representable::Decorator
  include Representable::JSON

  property :name
  collection :songs, decorator: SongRepresenter, class: Song
end
```

## Inline Representers

If you don't want to maintain two separate modules when nesting representations you can define the `SongRepresenter` inline.

```ruby
class AlbumRepresenter < Representable::Decorator
  include Representable::JSON

  property :name

  collection :songs, class: Song do
    property :title
    property :track
    collection :composers
  end
end
```

## More

Representable has many more features and can literally parse and render any kind of document to an arbitrary Ruby object graph.

Please check the [official documentation for more](https://trailblazer.to/2.1/docs/representable.html#representable-api).


## Installation

The representable gem runs with all Ruby versions >= 2.4.0.
t
```ruby
gem 'representable'
```

### Dependencies

Representable does a great job with JSON, it also features support for XML, YAML and pure ruby
hashes. But Representable did not bundle dependencies for JSON and XML.

If you want to use JSON, add the following to your Gemfile:

```ruby
gem 'multi_json'
```

If you want to use XML, add the following to your Gemfile:

```ruby
gem 'nokogiri'
```

## Copyright

Representable started as a heavily simplified fork of the ROXML gem. Big thanks to Ben Woosley for his extremely inspiring work.

* Copyright (c) 2011-2020 Nick Sutterer <apotonick@gmail.com>
* ROXML is Copyright (c) 2004-2009 Ben Woosley, Zak Mandhro and Anders Engstrom.

Representable is released under the [MIT License](https://www.opensource.org/licenses/MIT).
