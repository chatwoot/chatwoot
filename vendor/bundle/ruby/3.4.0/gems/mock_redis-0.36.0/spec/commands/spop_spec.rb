require 'spec_helper'

describe '#spop(key)' do
  before do
    @key = 'mock-redis-test:spop'

    @redises.sadd(@key, 'value')
  end

  it 'returns a member of the set' do
    @redises.spop(@key).should == 'value'
  end

  it 'removes a member of the set' do
    @redises.spop(@key)
    @redises.smembers(@key).should == []
  end

  it 'returns nil if the set is empty' do
    @redises.spop(@key)
    @redises.spop(@key).should be_nil
  end

  it 'returns an array if count is not nil' do
    @redises.sadd(@key, 'value2')
    @redises.spop(@key, 2).should == %w[value value2]
  end

  it 'returns only whats in the set' do
    @redises.spop(@key, 2).should == ['value']
    @redises.smembers(@key).should == []
  end

  it 'returns an empty array if count is not nil and the set it empty' do
    @redises.spop(@key)
    @redises.spop(@key, 100).should == []
  end

  it_should_behave_like 'a set-only command'
end
