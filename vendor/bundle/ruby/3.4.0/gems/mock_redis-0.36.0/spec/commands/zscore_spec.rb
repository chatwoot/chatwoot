require 'spec_helper'

describe '#zscore(key, member)' do
  before { @key = 'mock-redis-test:zscore' }

  it 'returns the score as a string' do
    @redises.zadd(@key, 0.25, 'foo').should == true
    @redises.zscore(@key, 'foo').should == 0.25
  end

  it 'handles integer members correctly' do
    member = 11
    @redises.zadd(@key, 0.25, member).should == true
    @redises.zscore(@key, member).should == 0.25
  end

  it 'returns nil if member is not present in the set' do
    @redises.zscore(@key, 'foo').should be_nil
  end

  it_should_behave_like 'a zset-only command'
end
