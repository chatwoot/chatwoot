require 'spec_helper'

describe '#watch(key [, key, ...)' do
  before do
    @key1 = 'mock-redis-test-watch1'
    @key2 = 'mock-redis-test-watch2'
  end

  it "returns 'OK'" do
    @redises.watch(@key1, @key2).should == 'OK'
  end

  it 'EXECs its MULTI on successes' do
    @redises.watch @key1, @key2 do
      @redises.multi do |multi|
        multi.set 'bar', 'baz'
      end
    end
    @redises.get('bar').should eq('baz')
  end
end
