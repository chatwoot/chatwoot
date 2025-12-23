require 'test_helper'

class PrepareTest < BaseTest
  class PreparerClass
    def initialize(object)
      @object = object
    end

    def ==(b)
      return unless b.instance_of?(PreparerClass)

      object == b.object
    end

    attr_reader :object
  end

  describe "#to_hash" do # TODO: introduce :representable option?
    representer! do
      property :song,
        :prepare       => lambda { |options| options[:binding][:arbitrary].new(options[:input]) },
        :arbitrary     => PreparerClass,
        :extend => true,
        :representable => false # don't call #to_hash.
    end

    let(:hit) { Struct.new(:song).new(song).extend(representer) }

    it "calls prepare:, nothing else" do
      # render(hit).must_equal_document(output)
      _(hit.to_hash).must_equal({"song" => PreparerClass.new(song)})
    end


    # it "calls #from_hash on the existing song instance, nothing else" do
    #   song_id = hit.song.object_id

    #   parse(hit, input)

    #   hit.song.title.must_equal "Suffer"
    #   hit.song.object_id.must_equal song_id
    # end
  end


  describe "#from_hash" do
    representer! do
      property :song,
        :prepare       => lambda { |options| options[:binding][:arbitrary].new(options[:input]) },
        :arbitrary     => PreparerClass,
        #:extend => true, # TODO: typed: true would be better.
        :instance => String.new, # pass_fragment
        :pass_options  => true,
        :representable => false # don't call #to_hash.
    end

    let(:hit) { Struct.new(:song).new.extend(representer) }

    it "calls prepare:, nothing else" do
      # render(hit).must_equal_document(output)
      hit.from_hash("song" => {})

      _(hit.song).must_equal(PreparerClass.new(String.new))
    end
  end
end