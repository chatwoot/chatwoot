require 'maxminddb'

describe MaxMindDB::Result::Postal do
  subject(:result) { described_class.new(raw_result) }

  context "with a result" do
    let(:raw_result) { {
      "code"=>"94043"
    } }

    its(:code) { should eq("94043") }
  end

  context "without a result" do
    let(:raw_result) { nil }

    its(:code) { should be_nil }
  end
end
