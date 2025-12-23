require 'spec_helper'

describe '#srem(key, member)' do
  before do
    @key = 'mock-redis-test:srem'

    @redises.sadd(@key, 'bert')
    @redises.sadd(@key, 'ernie')
  end

  it 'returns true if member is in the set' do
    @redises.srem(@key, 'bert').should == true
  end

  it 'returns false if member is not in the set' do
    @redises.srem(@key, 'cookiemonster').should == false
  end

  it 'removes member from the set' do
    @redises.srem(@key, 'ernie')
    @redises.smembers(@key).should == ['bert']
  end

  it 'stringifies member' do
    @redises.sadd(@key, '1')
    @redises.srem(@key, 1).should == true
  end

  it 'cleans up empty sets' do
    @redises.smembers(@key).each { |m| @redises.srem(@key, m) }
    @redises.get(@key).should be_nil
  end

  it 'supports a variable number of arguments' do
    @redises.srem(@key, %w[bert ernie]).should == 2
    @redises.get(@key).should be_nil
  end

  it 'allow passing an array of integers as argument' do
    @redises.sadd(@key, %w[1 2])
    @redises.srem(@key, [1, 2]).should == 2
  end

  it_should_behave_like 'a set-only command'
end
