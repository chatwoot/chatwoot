require 'spec_helper'

describe '#smove(source, destination, member)' do
  before do
    @src  = 'mock-redis-test:smove-source'
    @dest = 'mock-redis-test:smove-destination'

    @redises.sadd(@src, 1)
    @redises.sadd(@dest, 2)
  end

  it 'returns true if the member exists in src' do
    @redises.smove(@src, @dest, 1).should == true
  end

  it 'returns false if the member exists in src' do
    @redises.smove(@src, @dest, 'nope').should == false
  end

  it 'returns true if the member exists in src and dest' do
    @redises.sadd(@dest, 1)
    @redises.smove(@src, @dest, 1).should == true
  end

  it 'moves member from source to destination' do
    @redises.smove(@src, @dest, 1)
    @redises.sismember(@dest, 1).should == true
    @redises.sismember(@src, 1).should == false
  end

  it 'cleans up empty sets' do
    @redises.smove(@src, @dest, 1)
    @redises.get(@src).should be_nil
  end

  it 'treats a nonexistent value as an empty set' do
    @redises.smove('mock-redis-test:nonesuch', @dest, 1).should == false
  end

  it_should_behave_like 'a set-only command'
end
