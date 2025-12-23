require 'spec_helper'
require 'crc_examples'
require 'digest/crc24'

describe Digest::CRC24 do
  let(:string) { '1234567890' }
  let(:expected) { '8c0072' }

  it_should_behave_like "CRC"
end
