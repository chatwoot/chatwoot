require 'spec_helper'
require 'crc_examples'
require 'digest/crc64_xz'

describe Digest::CRC64XZ do
  let(:string)   { '1234567890' }
  let(:expected) { 'b1cb31bbb4a2b2be' }

  it_should_behave_like "CRC"
end
