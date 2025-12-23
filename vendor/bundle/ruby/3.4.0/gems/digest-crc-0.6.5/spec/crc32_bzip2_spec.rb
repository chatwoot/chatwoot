require 'spec_helper'
require 'crc_examples'
require 'digest/crc32_bzip2'

describe Digest::CRC32BZip2 do
  let(:string) { '1234567890' }
  let(:expected) { '506853b6' }

  it_should_behave_like "CRC"
end
