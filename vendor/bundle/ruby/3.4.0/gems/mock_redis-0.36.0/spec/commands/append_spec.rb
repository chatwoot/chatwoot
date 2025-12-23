require 'spec_helper'

describe '#append(key, value)' do
  before { @key = 'mock-redis-test:append' }

  it 'returns the new length of the string' do
    @redises.set(@key, 'porkchop')
    @redises.append(@key, 'sandwiches').should == 18
  end

  it 'appends value to the previously-stored value' do
    @redises.set(@key, 'porkchop')
    @redises.append(@key, 'sandwiches')

    @redises.get(@key).should == 'porkchopsandwiches'
  end

  it 'treats a missing key as an empty string' do
    @redises.append(@key, 'foo')
    @redises.get(@key).should == 'foo'
  end

  it_should_behave_like 'a string-only command'
end
