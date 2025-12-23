require 'spec_helper'
require 'crc_examples'
require 'digest/crc32_posix'

describe Digest::CRC32POSIX do
  let(:string) { '1234567890' }
  let(:expected) { 'c181fd8e' }

  it_should_behave_like "CRC"
end
