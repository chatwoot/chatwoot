require 'pry-byebug'
require 'representable'

require 'minitest/autorun'
require 'test_xml/mini_test'

require "representable/debug"
require 'minitest/assertions'

module MiniTest::Assertions
  def assert_equal_xml(text, subject)
    assert_equal (text.gsub("\n", "").gsub(/(\s\s+)/, "")), subject.gsub("\n", "").gsub(/(\s\s+)/, "")
  end
end
String.infect_an_assertion :assert_equal_xml, :must_xml

# TODO: delete all that in 4.0:
class Album
  attr_accessor :songs, :best_song
  def initialize(songs=nil, best_song=nil)
    @songs      = songs
    @best_song  = best_song
  end

  def ==(other)
    songs == other.songs and best_song == other.best_song
  end
end

class Song
  attr_accessor :name, :track # never change this, track rendered with Rails#to_json.
  def initialize(name=nil, track=nil)
    @name   = name
    @track  = track
  end

  def ==(other)
    name == other.name and track == other.track
  end
end

module XmlHelper
  def xml(document)
    Nokogiri::XML(document).root
  end
end

module AssertJson
  module Assertions
    def assert_json(expected, actual, msg=nil)
      msg = message(msg, "") { diff expected, actual }
      assert_equal(expected.split("").sort, actual.split("").sort, msg)
    end
  end
end

MiniTest::Spec.class_eval do
  include AssertJson::Assertions
  include XmlHelper

  def self.for_formats(formats)
    formats.each do |format, cfg|
      mod, output, input = cfg
      yield format, mod, output, input
    end
  end

  def render(object, *args)
    AssertableDocument.new(object.send("to_#{format}", *args), format)
  end

  def parse(object, input, *args)
    object.send("from_#{format}", input, *args)
  end

  class AssertableDocument
    attr_reader :document

    def initialize(document, format)
      @document, @format = document, format
    end

    def must_equal_document(*args)
      return document.must_equal_xml(*args) if @format == :xml
      document.must_equal(*args)
    end
  end

  def self.representer!(options={}, &block)
    fmt = options # we need that so the 2nd call to ::let(within a ::describe) remembers the right format.

    name   = options[:name]   || :representer
    format = options[:module] || Representable::Hash

    let(name) do
      mod = options[:decorator] ? Class.new(Representable::Decorator) : Module.new

      inject_representer(mod, fmt)

      mod.module_eval do
        include format
        instance_exec(&block)
      end

      mod
    end

    undef :inject_representer if method_defined? :inject_representer

    def inject_representer(mod, options)
      return unless options[:inject]

      injected_name = options[:inject]
      injected = send(injected_name) # song_representer
      mod.singleton_class.instance_eval do
        define_method(injected_name) { injected }
      end
    end
  end

  module TestMethods
    def representer_for(modules=[Representable::Hash], &block)
      Module.new do
        extend TestMethods
        include(*modules)
        module_exec(&block)
      end
    end

    alias_method :representer!, :representer_for
  end
  include TestMethods
end

class BaseTest < MiniTest::Spec
  let(:new_album)  { OpenStruct.new.extend(representer) }
  let(:album)      { OpenStruct.new(:songs => ["Fuck Armageddon"]).extend(representer) }
  let(:song) { OpenStruct.new(:title => "Resist Stance") }
  let(:song_representer) { Module.new do include Representable::Hash; property :title end  }

end

Band = Struct.new(:id, :name) do
  def [](*attrs)
    attrs.collect { |attr| send(attr) }
  end
end
