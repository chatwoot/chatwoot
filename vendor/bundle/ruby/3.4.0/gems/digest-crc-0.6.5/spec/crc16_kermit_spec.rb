require 'spec_helper'
require 'crc_examples'
require 'digest/crc16_kermit'

describe Digest::CRC16Kermit do
  let(:string)   { '1234567890' }
  let(:expected) { '286b' }

  it_should_behave_like "CRC"
end
