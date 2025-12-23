require 'spec_helper'
require 'crc_examples'
require 'digest/crc16_modbus'

describe Digest::CRC16Modbus do
  let(:string)   { '1234567890' }
  let(:expected) { 'c20a' }

  it_should_behave_like "CRC"
end
