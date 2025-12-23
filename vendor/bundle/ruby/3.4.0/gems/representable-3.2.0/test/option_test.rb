# frozen_string_literal: true

require 'test_helper'

class OptionTest < MiniTest::Spec
  class Callable
    include Uber::Callable
    def call(*); "callable" end
  end

  class MyRepresenter < Representable::Decorator
    include Representable::JSON

    property :static,   getter: "static"
    property :symbol,   getter: :symbol
    property :proc,     getter: ->(*) { "proc" }
    property :callable, getter: Callable.new
  end

  Album = Struct.new(:static) do
    def symbol(*); "symbol" end
  end

  let(:album_representer) { MyRepresenter.new(Album.new) }

  describe ::Representable::Option do
    it "supports all types of callables (method, proc, static etc)" do
      _(album_representer.to_hash).must_equal({
        "static"    => "static",
        "symbol"    => "symbol",
        "proc"      => "proc",
        "callable"  => "callable",
      })
    end
  end
end
