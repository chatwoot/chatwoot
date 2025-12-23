require 'spec_helper'
require 'crc_examples'
require 'digest/crc8'

describe Digest::CRC8 do
  let(:string)   { '1234567890' }
  let(:expected) { '52' }

  it_should_behave_like "CRC"
end
