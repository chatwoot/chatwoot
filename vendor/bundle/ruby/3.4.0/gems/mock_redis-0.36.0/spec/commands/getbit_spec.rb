require 'spec_helper'

describe '#getbit(key, offset)' do
  before do
    @key = 'mock-redis-test:getbit'
    @redises.set(@key, 'h') # ASCII 0x68
  end

  it 'gets the bits from the key' do
    @redises.getbit(@key, 0).should == 0
    @redises.getbit(@key, 1).should == 1
    @redises.getbit(@key, 2).should == 1
    @redises.getbit(@key, 3).should == 0
    @redises.getbit(@key, 4).should == 1
    @redises.getbit(@key, 5).should == 0
    @redises.getbit(@key, 6).should == 0
    @redises.getbit(@key, 7).should == 0
  end

  it 'returns 0 for out-of-range bits' do
    @redises.getbit(@key, 100).should == 0
  end

  it 'does not modify the stored value for out-of-range bits' do
    @redises.getbit(@key, 100)
    @redises.get(@key).should == 'h'
  end

  it 'treats nonexistent keys as empty strings' do
    @redises.getbit('mock-redis-test:not-found', 0).should == 0
  end

  it_should_behave_like 'a string-only command'
end
