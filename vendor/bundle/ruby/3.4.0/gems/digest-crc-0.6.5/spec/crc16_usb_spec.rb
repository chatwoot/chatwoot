require 'spec_helper'
require 'crc_examples'
require 'digest/crc16_usb'

describe Digest::CRC16USB do
  let(:string)   { '1234567890' }
  let(:expected) { '3df5' }

  it_should_behave_like "CRC"
end
