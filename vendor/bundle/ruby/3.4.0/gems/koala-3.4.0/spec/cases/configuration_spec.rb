require "spec_helper"

RSpec.describe Koala::Configuration do
  let(:config) { Koala::Configuration.new }

  it "defaults the HTTPService's DEFAULT_SERVERS" do
    Koala::HTTPService::DEFAULT_SERVERS.each_pair do |key, value|
      expect(config.public_send(key)).to eq(value)
    end
  end
end
