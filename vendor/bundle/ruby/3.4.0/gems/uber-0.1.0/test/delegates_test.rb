require 'test_helper'
require 'uber/delegates'

class DelegatesTest < MiniTest::Spec
  class Song
    extend Uber::Delegates

    delegates :model, :title

    def model
      Struct.new(:title).new("Helloween")
    end

    def title
      super.downcase
    end
  end

  # allows overriding in class.
  it { Song.new.title.must_equal "helloween" }


  module Title
    extend Uber::Delegates

    delegates :model, :title, :id
  end

  class Album
    include Title

    def model
      Struct.new(:title, :id).new("Helloween", 1)
    end

    def title
      super.downcase
    end
  end

  # allows overriding in class inherited from module.
  it { Album.new.title.must_equal "helloween" }
  it { Album.new.id.must_equal 1 }
end