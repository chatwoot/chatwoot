require 'spec_helper'
require 'crc_examples'
require 'digest/crc5'

describe Digest::CRC5 do
  let(:string)   { '1234567890' }
  let(:expected) { '01' }

  it_should_behave_like "CRC"
end
