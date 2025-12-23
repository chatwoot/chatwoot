require 'spec_helper'
require 'crc_examples'
require 'digest/crc64'

describe Digest::CRC64 do
  let(:string)   { '1234567890' }
  let(:expected) { 'bc66a5a9388a5bef' }

  it_should_behave_like "CRC"
end
