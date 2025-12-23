require 'spec_helper'

describe '#sismember(key, member)' do
  before do
    @key = 'mock-redis-test:sismember'
    @redises.sadd(@key, 'whiskey')
    @redises.sadd(@key, 'beer')
  end

  it 'returns true if member is in set' do
    @redises.sismember(@key, 'whiskey').should == true
    @redises.sismember(@key, 'beer').should == true
  end

  it 'returns false if member is not in set' do
    @redises.sismember(@key, 'cola').should == false
  end

  it 'stringifies member' do
    @redises.sadd(@key, '1')
    @redises.sismember(@key, 1).should == true
  end

  it 'treats a nonexistent value as an empty set' do
    @redises.sismember('mock-redis-test:nonesuch', 'beer').should == false
  end

  it_should_behave_like 'a set-only command'
end
