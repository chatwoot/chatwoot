require 'spec_helper'

describe '#smismember(key, *members)' do
  before do
    @key = 'mock-redis-test:smismember'
    @redises.sadd(@key, 'whiskey')
    @redises.sadd(@key, 'beer')
  end

  it 'returns true if member is in set' do
    @redises.smismember(@key, 'whiskey').should == [true]
    @redises.smismember(@key, 'beer').should == [true]
    @redises.smismember(@key, 'whiskey', 'beer').should == [true, true]
    @redises.smismember(@key, %w[whiskey beer]).should == [true, true]
  end

  it 'returns false if member is not in set' do
    @redises.smismember(@key, 'cola').should == [false]
    @redises.smismember(@key, 'whiskey', 'cola').should == [true, false]
    @redises.smismember(@key, %w[whiskey beer cola]).should == [true, true, false]
  end

  it 'stringifies member' do
    @redises.sadd(@key, '1')
    @redises.smismember(@key, 1).should == [true]
    @redises.smismember(@key, [1]).should == [true]
  end

  it 'treats a nonexistent value as an empty set' do
    @redises.smismember('mock-redis-test:nonesuch', 'beer').should == [false]
  end

  it_should_behave_like 'a set-only command'
end
