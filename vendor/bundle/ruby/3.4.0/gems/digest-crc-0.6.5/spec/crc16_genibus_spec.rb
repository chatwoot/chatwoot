require 'spec_helper'
require 'crc_examples'
require 'digest/crc16_genibus'

describe Digest::CRC16Genibus do
  let(:string)   { '1234567890' }
  let(:expected) { 'cde7' }

  it_should_behave_like "CRC"
end
