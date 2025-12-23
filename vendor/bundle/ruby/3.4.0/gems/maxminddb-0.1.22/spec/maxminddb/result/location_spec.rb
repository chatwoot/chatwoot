require 'maxminddb'
require 'rspec/its'

describe MaxMindDB::Result::Location do
  subject(:result) { described_class.new(raw_result) }

  context "with a result" do
    let(:raw_result) { {
      "latitude"=>37.419200000000004,
      "longitude"=>-122.0574,
      "metro_code"=>"807",
      "time_zone"=>"America/Los_Angeles",
      "accuracy_radius"=>1000
    } }

    its(:latitude) { should eq(37.419200000000004) }
    its(:longitude) { should eq(-122.0574) }
    its(:metro_code) { should eq("807") }
    its(:time_zone) { should eq("America/Los_Angeles") }
    its(:accuracy_radius) { should eq(1000) }
  end

  context "without a result" do
    let(:raw_result) { nil }

    its(:latitude) { should be_nil }
    its(:longitude) { should be_nil }
    its(:metro_code) { should be_nil }
    its(:time_zone) { should be_nil }
    its(:accuracy_radius) { should be_nil }
  end
end
