require 'spec_helper'
require 'digest/crc'

describe Digest::CRC do
  describe "#block_length" do
    it { expect(subject.block_length).to be 1 }
  end

  describe ".pack" do
    subject { described_class }

    it do
      expect { subject.pack(0) }.to raise_error(NotImplementedError)
    end
  end

  describe "#update" do
    it do
      expect { subject.update('') }.to raise_error(NotImplementedError)
    end
  end

  context "when inherited" do
    subject do
      Class.new(described_class).tap do |klass|
        klass::WIDTH = 16

        klass::INIT_CRC = 0x01

        klass::XOR_MASK = 0x02

        klass::TABLE = [0x01, 0x02, 0x03, 0x04].freeze
      end
    end

    it "should override WIDTH" do
      expect(subject::WIDTH).not_to be described_class::WIDTH
    end

    it "should override INIT_CRC" do
      expect(subject::INIT_CRC).not_to be described_class::INIT_CRC
    end

    it "should override XOR_MASK" do
      expect(subject::XOR_MASK).not_to be described_class::XOR_MASK
    end

    it "should override TABLE" do
      expect(subject::TABLE).not_to be described_class::TABLE
    end

    describe "#initialize" do
      let(:instance) { subject.new }

      it "should initialize @init_crc" do
        expect(instance.instance_variable_get("@init_crc")).to be subject::INIT_CRC
      end

      it "should initialize @xor_mask" do
        expect(instance.instance_variable_get("@xor_mask")).to be subject::XOR_MASK
      end

      it "should initialize @width" do
        expect(instance.instance_variable_get("@width")).to be subject::WIDTH
      end

      it "should initialize @table" do
        expect(instance.instance_variable_get("@table")).to be subject::TABLE
      end
    end
  end
end
