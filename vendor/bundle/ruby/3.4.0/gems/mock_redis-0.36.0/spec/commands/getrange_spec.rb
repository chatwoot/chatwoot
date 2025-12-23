require 'spec_helper'

describe '#getrange(key, start, stop)' do
  before do
    @key = 'mock-redis-test:getrange'
    @redises.set(@key, 'This is a string')
  end

  it 'returns a substring' do
    @redises.getrange(@key, 0, 3).should == 'This'
  end

  it 'works with negative indices' do
    @redises.getrange(@key, -3, -1).should == 'ing'
  end

  it 'limits the result to the actual length of the string' do
    @redises.getrange(@key, 10, 100).should == 'string'
  end

  it_should_behave_like 'a string-only command'
end
