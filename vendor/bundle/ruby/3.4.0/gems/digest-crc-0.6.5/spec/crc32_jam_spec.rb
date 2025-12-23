require 'spec_helper'
require 'crc_examples'
require 'digest/crc32_jam'

describe Digest::CRC32Jam do
  let(:string) { '1234567890' }
  let(:expected) { 'd9e2511a' }

  it_should_behave_like "CRC"
end
