require 'spec_helper'
require 'digest/crc16_qt'

describe "Digest::CRC16QT" do
  subject { Digest::CRC16QT }

  it "should be an alias to Digest::CRC16X25" do
    expect(subject).to be < Digest::CRC16X25
  end
end
