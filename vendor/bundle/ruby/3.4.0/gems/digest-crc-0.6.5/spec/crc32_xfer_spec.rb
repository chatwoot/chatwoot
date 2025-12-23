require 'spec_helper'
require 'crc_examples'
require 'digest/crc32_xfer'

describe Digest::CRC32XFER do
  let(:string) { '1234567890' }
  let(:expected) { '0be368eb' }

  it_should_behave_like "CRC"
end
