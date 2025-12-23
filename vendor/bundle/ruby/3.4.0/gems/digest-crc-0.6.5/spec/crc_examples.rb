require 'spec_helper'

shared_examples_for "CRC" do
  it "should calculate a checksum for text" do
    expect(described_class.hexdigest(string)).to be == expected
  end

  it "should calculate a checksum for multiple data" do
    middle = (string.length / 2)

    chunk1 = string[0...middle]
    chunk2 = string[middle..-1]

    crc = subject
    crc << chunk1
    crc << chunk2

    expect(crc.hexdigest).to be == expected
  end

  it "should provide direct access to the checksum value" do
    crc = subject
    crc << string

    expect(crc.checksum).to be == expected.to_i(16)
  end

  if defined?(Ractor)
    it "should calculate CRC inside ractor" do
      digest = Ractor.new(described_class, string) do |klass, string|
        klass.hexdigest(string)
      end.take

      expect(digest).to eq expected
    end
  end
end
