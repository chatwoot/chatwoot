require 'spec_helper'
require 'crc_examples'
require 'digest/crc16_zmodem'

describe Digest::CRC16ZModem do
  let(:string) { '1234567890' }
  let(:expected) { 'd321' }

  it_should_behave_like "CRC"
end
