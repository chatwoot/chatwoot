require 'spec_helper'
require 'crc_examples'
require 'digest/crc64_jones'

describe Digest::CRC64Jones do
  let(:string)   { '1234567890' }
  let(:expected) { '68a745ba133af9bd' }

  it_should_behave_like "CRC"
end
