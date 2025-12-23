require 'spec_helper'
require 'crc_examples'
require 'digest/crc8_1wire'

describe Digest::CRC8_1Wire do
  let(:string)   { '1234567890' }
  let(:expected) { '4f' }

  it_should_behave_like "CRC"
end

describe "Digest::CRC81Wire" do
  subject { Digest::CRC81Wire }

  it { expect(subject).to eq(Digest::CRC8_1Wire) }
end
