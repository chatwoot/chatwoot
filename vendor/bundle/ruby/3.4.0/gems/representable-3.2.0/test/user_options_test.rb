require "test_helper"

class UserOptionsTest < Minitest::Spec
  Song = Struct.new(:title)

  representer! do
    property :title, if: ->(options) { options[:user_options][:visible] }
  end

  it { _(Song.new("Run With It").extend(representer).to_hash).must_equal({}) }
  it { _(Song.new("Run With It").extend(representer).to_hash(user_options: {visible: true})).must_equal({"title"=>"Run With It"}) }
  it { _(Song.new("Run With It").extend(representer).from_hash("title"=>"Business Conduct").title).must_equal "Run With It" }
  it { _(Song.new("Run With It").extend(representer).from_hash({"title"=>"Business Conduct"}, user_options: {visible: true}).title).must_equal "Business Conduct" }
end
# Representable.deprecations=false