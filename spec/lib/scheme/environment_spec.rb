require 'spec_helper'
require_relative '../../../lib/scheme'

RSpec.describe Scheme::Environment do
  let(:root) { described_class.new }
  let(:leaf) { 20_000.times.reduce(root) { |parent, _| described_class.new(parent) } }

  it 'reads a distant binding without consuming the Ruby call stack' do
    root.define(:value, 42)
    expect(leaf.get(:value)).to eq(42)
  end

  it 'updates the original distant cell rather than copying its value' do
    root.define(:value, 42)
    expect(leaf.cell(:value)).to equal(root.cell(:value))
    leaf.set(:value, 43)
    expect(root.get(:value)).to eq(43)
  end

  it 'reports unbound identifiers after searching a deep chain' do
    expect { leaf.get(:missing) }.to raise_error(Scheme::Error, /unbound identifier: missing/)
    expect { leaf.set(:missing, 1) }.to raise_error(Scheme::Error, /cannot set unbound identifier: missing/)
  end

  it 'retains false values and respects the nearest binding' do
    root.define(:value, 42)
    leaf.define(:value, false)
    expect(leaf.get(:value)).to be(false)
    leaf.set(:value, 7)
    expect(root.get(:value)).to eq(42)
    expect(leaf.get(:value)).to eq(7)
  end

  it 'does not skip an uninitialized binding to read an outer value' do
    root.define(:value, 42)
    leaf.define(:value, Scheme::UNINITIALIZED)
    expect { leaf.get(:value) }.to raise_error(Scheme::Error, /before initialization: value/)
  end
end
