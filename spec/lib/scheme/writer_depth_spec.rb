require 'spec_helper'
require_relative '../../../lib/scheme'

RSpec.describe Scheme, '.write' do
  let(:depth) { 20_000 }

  it 'writes deeply nested pairs without recursion or truncation' do
    value = depth.times.reduce(7) { |child, _| described_class.list([child]) }
    expect(described_class.write(value)).to eq("#{'(' * depth}7#{')' * depth}")
  end

  it 'writes deeply nested vectors without recursion or truncation' do
    value = depth.times.reduce(7) { |child, _| Scheme::Vector.new([child]) }
    expect(described_class.write(value)).to eq("#{'#(' * depth}7#{')' * depth}")
  end

  it 'writes deep improper lists containing compound tails' do
    value = depth.times.reduce(7) { |child, _| Scheme::Pair.new(1, Scheme::Vector.new([child])) }
    expect(described_class.write(value)).to eq("#{'(1 . #(' * depth}7#{'))' * depth}")
  end

  it 'terminates on a cycle between pairs and vectors' do
    pair = Scheme::Pair.new(:root)
    vector = Scheme::Vector.new([pair])
    pair.cdr = vector
    expect(described_class.write(pair)).to eq('(root . #(#<cycle>))')
  end

  it 'keeps shared structure readable rather than misidentifying it as cyclic' do
    shared = described_class.list([1, 2])
    value = Scheme::Vector.new([described_class.list([shared, shared]), shared])
    expect(described_class.write(value)).to eq('#(((1 2) (1 2)) (1 2))')
  end

  it 'keeps errors involving deep data catchable within Scheme' do
    runtime = Scheme::Runtime.new
    value = depth.times.reduce(7) { |child, _| described_class.list([child]) }
    runtime.define('deep-value', min: 0, max: 0) { value }
    expect(runtime.evaluate('(guard (e (else (error-object? e))) (+ (deep-value) 1))')).to be(true)
    expect(runtime.evaluate('(guard (e (else (error-object? e))) ((deep-value)))')).to be(true)
  end

  it 'preserves the Scheme exception object when deep data is raised without a handler' do
    runtime = Scheme::Runtime.new
    value = depth.times.reduce(7) { |child, _| Scheme::Vector.new([child]) }
    runtime.define('deep-value', min: 0, max: 0) { value }
    expect { runtime.evaluate('(raise (deep-value))') }.to raise_error(Scheme::UncaughtError) do |error|
      expect(error.object).to equal(value)
    end
  end
end
