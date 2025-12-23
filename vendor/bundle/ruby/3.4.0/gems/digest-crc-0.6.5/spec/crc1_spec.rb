require 'spec_helper'
require 'crc_examples'
require 'digest/crc1'

describe Digest::CRC1 do
  let(:string) { '1234567890' }
  let(:expected) { '0d' }

  it_should_behave_like "CRC"
end
