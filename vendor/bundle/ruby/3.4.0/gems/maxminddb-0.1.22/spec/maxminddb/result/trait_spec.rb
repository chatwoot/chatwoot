require 'maxminddb'

describe MaxMindDB::Result::Traits do
  subject(:result) { described_class.new(raw_result) }

  context "with an is_anonymous_proxy result" do
    let(:raw_result) { {
      "is_anonymous_proxy"=>true
    } }

    its(:is_anonymous_proxy) { should eq(true) }
    its(:is_satellite_provider) { should eq(nil) }
  end

  context "with an is_satellite_provider result" do
    let(:raw_result) { {
      "is_satellite_provider"=>true
    } }

    its(:is_anonymous_proxy) { should eq(nil) }
    its(:is_satellite_provider) { should eq(true) }
  end

  context "with an all traits result" do
    let(:raw_result) { {
      "is_anonymous_proxy"=>true,
      "is_satellite_provider"=>true
    } }

    its(:is_anonymous_proxy) { should eq(true) }
    its(:is_satellite_provider) { should eq(true) }
  end

  context "without a result" do
    let(:raw_result) { nil }

    its(:is_anonymous_proxy) { should eq(nil) }
    its(:is_satellite_provider) { should eq(nil) }
  end
end
