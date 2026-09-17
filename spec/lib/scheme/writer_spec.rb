require 'spec_helper'
require_relative '../../../lib/scheme'

RSpec.describe Scheme, '.write' do
  [
    true, false, 123, -45, Rational(2, 3), 0.5, Float::INFINITY, -Float::INFINITY,
    '', 'λ🙂', "line\nnext\ttab", "\0\e\x01\x7f", 'a"b\c',
    :ordinary, :+, :'two words', :'123', :'a|b', :'a\\b', :'', :'#t', :'.', :'λ',
    Scheme::Character.new(' '), Scheme::Character.new("\n"), Scheme::Character.new('λ')
  ].each do |value|
    it "writes a readable representation of #{value.inspect}" do
      source = described_class.write(value)
      parsed = Scheme::Reader.new(source).read_all

      expect(parsed.length).to eq(1)
      expect(described_class.equal?(parsed.first, value)).to be(true)
    end
  end

  it 'preserves the type of compound data when read back' do
    original = Scheme::Reader.new('((a . b) #(1 "two") #u8(0 255) ())').read_all.first
    parsed = Scheme::Reader.new(described_class.write(original)).read_all.first

    expect(described_class.equal?(original, parsed)).to be(true)
  end

  it 'does not introduce Ruby interpolation escapes into Scheme text' do
    value = '#{not interpolation}' # rubocop:disable Lint/InterpolationCheck -- Literal Scheme text, not Ruby interpolation.
    expect(Scheme::Reader.new(described_class.write(value)).read_all).to eq([value])
  end

  it 'writes NaN as a Scheme numeric literal' do
    source = described_class.write(Float::NAN)
    expect(source).to eq('+nan.0')
    expect(Scheme::Reader.new(source).read_all.first).to be_nan
  end

  it 'terminates when writing a cyclic pair' do
    pair = Scheme::Pair.new(1)
    pair.cdr = pair

    expect(described_class.write(pair)).to eq('(1 . #<cycle>)')
  end

  it 'terminates when writing a self-referencing vector' do
    vector = Scheme::Vector.new([])
    vector.items << vector

    expect(described_class.write(vector)).to eq('#(#<cycle>)')
  end

  it 'does not mistake shared but noncyclic data for a cycle' do
    shared = described_class.list([1, 2])
    expect(described_class.write(described_class.list([shared, shared]))).to eq('((1 2) (1 2))')
  end
end
