# frozen_string_literal: true

require 'spec_helper'

describe Hashdiff do
  it 'is able to decode property path' do
    decoded = described_class.send(:decode_property_path, 'a.b[0].c.city[5]')
    decoded.should == ['a', 'b', 0, 'c', 'city', 5]
  end

  it 'is able to decode property path with custom delimiter' do
    decoded = described_class.send(:decode_property_path, "a\tb[0]\tc\tcity[5]", "\t")
    decoded.should == ['a', 'b', 0, 'c', 'city', 5]
  end

  it 'is able to tell similiar hash' do
    a = { 'a' => 1, 'b' => 2, 'c' => 3, 'd' => 4, 'e' => 5 }
    b = { 'a' => 1, 'b' => 2, 'c' => 3, 'e' => 5 }
    described_class.similar?(a, b).should be true
    described_class.similar?(a, b, similarity: 1).should be false
  end

  it 'is able to tell similiar empty hash' do
    described_class.similar?({}, {}, similarity: 1).should be true
  end

  it 'is able to tell similiar empty array' do
    described_class.similar?([], [], similarity: 1).should be true
  end

  it 'is able to tell similiar hash with values within tolerance' do
    a = { 'a' => 1.5, 'b' => 2.25, 'c' => 3, 'd' => 4, 'e' => 5 }
    b = { 'a' => 1.503, 'b' => 2.22, 'c' => 3, 'e' => 5 }
    described_class.similar?(a, b, numeric_tolerance: 0.05).should be true
    described_class.similar?(a, b).should be false
  end

  it 'is able to tell numbers and strings' do
    described_class.similar?(1, 2).should be false
    described_class.similar?('a', 'b').should be false
    described_class.similar?('a', [1, 2, 3]).should be false
    described_class.similar?(1, 'a' => 1, 'b' => 2, 'c' => 3, 'e' => 5).should be false
  end

  it 'is able to tell true when similarity == 0.5' do
    a = { 'value' => 'New1', 'onclick' => 'CreateNewDoc()' }
    b = { 'value' => 'New', 'onclick' => 'CreateNewDoc()' }

    described_class.similar?(a, b, similarity: 0.5).should be true
  end

  it 'is able to tell false when similarity == 0.5' do
    a = { 'value' => 'New1', 'onclick' => 'open()' }
    b = { 'value' => 'New', 'onclick' => 'CreateNewDoc()' }

    described_class.similar?(a, b, similarity: 0.5).should be false
  end

  describe '.compare_values' do
    it 'compares numeric values exactly when no tolerance' do
      expect(described_class.compare_values(10.004, 10.003)).to be false
    end

    it 'allows tolerance with numeric values' do
      expect(described_class.compare_values(10.004, 10.003, numeric_tolerance: 0.01)).to be true
    end

    it 'compares different objects without tolerance' do
      expect(described_class.compare_values('hats', 'ninjas')).to be false
    end

    it 'compares other objects with tolerance' do
      expect(described_class.compare_values('hats', 'ninjas', numeric_tolerance: 0.01)).to be false
    end

    it 'compares same objects without tolerance' do
      expect(described_class.compare_values('horse', 'horse')).to be true
    end

    it 'compares strings for spaces exactly by default' do
      expect(described_class.compare_values(' horse', 'horse')).to be false
    end

    it 'compares strings for capitalization exactly by default' do
      expect(described_class.compare_values('horse', 'Horse')).to be false
    end

    it 'strips strings before comparing when requested' do
      expect(described_class.compare_values(' horse', 'horse', strip: true)).to be true
    end

    it 'ignores string case when requested' do
      expect(described_class.compare_values('horse', 'Horse', case_insensitive: true)).to be true
    end
  end

  describe '.comparable?' do
    it 'identifies hashes as comparable' do
      expect(described_class.comparable?({}, {})).to be true
    end

    it 'identifies a subclass of Hash to be comparable with a Hash' do
      other = Class.new(Hash)
      expect(described_class.comparable?(other.new, {})).to be true
    end

    it 'identifies a Hash to be comparable with a subclass of Hash' do
      other = Class.new(Hash)
      expect(described_class.comparable?({}, other.new)).to be true
    end

    it 'does not identify a Numeric as comparable with a Hash' do
      expect(described_class.comparable?(1, {})).to be false
    end
  end
end
