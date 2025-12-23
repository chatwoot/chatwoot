require 'spec_helper'
require 'crc_examples'
require 'digest/crc16_ccitt'

describe Digest::CRC16CCITT do
  let(:string)   { '1234567890' }
  let(:expected) { '3218' }

  it_should_behave_like "CRC"
end
