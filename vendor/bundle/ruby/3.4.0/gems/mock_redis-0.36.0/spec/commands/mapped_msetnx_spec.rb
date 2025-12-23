require 'spec_helper'

describe '#mapped_msetnx(hash)' do
  before do
    @key1 = 'mock-redis-test:a'
    @key2 = 'mock-redis-test:b'
    @key3 = 'mock-redis-test:c'

    @redises.set(@key1, '1')
    @redises.set(@key2, '2')
  end

  it 'sets properly when none collide' do
    @redises.mapped_msetnx(@key3 => 'three').should eq(true)
    @redises.get(@key1).should eq('1') # existed; untouched
    @redises.get(@key2).should eq('2') # existed; untouched
    @redises.get(@key3).should eq('three')
  end

  it 'does not set any when any collide' do
    @redises.mapped_msetnx(@key1 => 'one', @key3 => 'three').should eq(false)
    @redises.get(@key1).should eq('1') # existed; untouched
    @redises.get(@key2).should eq('2') # existed; untouched
    @redises.get(@key3).should be_nil
  end
end
