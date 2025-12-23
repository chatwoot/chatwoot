require 'spec_helper'

describe '#smembers(key)' do
  before { @key = 'mock-redis-test:smembers' }

  it 'returns [] for an empty set' do
    @redises.smembers(@key).should == []
  end

  it "returns the set's members" do
    @redises.sadd(@key, 'Hello')
    @redises.sadd(@key, 'World')
    @redises.sadd(@key, 'Test')
    @redises.smembers(@key).should == %w[Test World Hello]
  end

  it 'returns unfrozen copies of the input' do
    input = 'a string'
    @redises.sadd(@key, input)
    output = @redises.smembers(@key).first

    expect(output).to eq input
    expect(output).to_not equal input
    expect(output).to_not be_frozen
  end

  it_should_behave_like 'a set-only command'
end
