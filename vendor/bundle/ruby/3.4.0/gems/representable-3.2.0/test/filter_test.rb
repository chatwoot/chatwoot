require 'test_helper'

class FilterPipelineTest < MiniTest::Spec
  let(:block1) { lambda { |input, options| "1: #{input}" } }
  let(:block2) { lambda { |input, options| "2: #{input}" } }

  subject { Representable::Pipeline[block1, block2] }

  it { _(subject.call("Horowitz", {})).must_equal "2: 1: Horowitz" }
end


class FilterTest < MiniTest::Spec
  representer! do
    property :title

    property :track,
      :parse_filter  => lambda { |input, options| "#{input.downcase},#{options[:doc]}" },
      :render_filter => lambda { |val, options| "#{val.upcase},#{options[:doc]},#{options[:options][:user_options]}" }
  end

  # gets doc and options.
  it {
    song = OpenStruct.new.extend(representer).from_hash("title" => "VULCAN EARS", "track" => "Nine")
    _(song.title).must_equal "VULCAN EARS"
    _(song.track).must_equal "nine,{\"title\"=>\"VULCAN EARS\", \"track\"=>\"Nine\"}"
  }

  it { _(OpenStruct.new("title" => "vulcan ears", "track" => "Nine").extend(representer).to_hash).must_equal( {"title"=>"vulcan ears", "track"=>"NINE,{\"title\"=>\"vulcan ears\"},{}"}) }


  describe "#parse_filter" do
    representer! do
      property :track,
        :parse_filter => [
          lambda { |input, options| "#{input}-1" },
          lambda { |input, options| "#{input}-2" }],
        :render_filter => [
          lambda { |val, options| "#{val}-1" },
          lambda { |val, options| "#{val}-2" }]
    end

    # order matters.
    it { _(OpenStruct.new.extend(representer).from_hash("track" => "Nine").track).must_equal "Nine-1-2" }
    it { _(OpenStruct.new("track" => "Nine").extend(representer).to_hash).must_equal({"track"=>"Nine-1-2"}) }
  end
end


# class RenderFilterTest < MiniTest::Spec
#   representer! do
#     property :track, :render_filter => [lambda { |val, options| "#{val}-1" } ]
#     property :track, :render_filter => [lambda { |val, options| "#{val}-2" } ], :inherit => true
#   end

#   it { OpenStruct.new("track" => "Nine").extend(representer).to_hash.must_equal({"track"=>"Nine-1-2"}) }
# end