require 'spec_helper'

describe '#llen(key)' do
  before { @key = 'mock-redis-test:78407' }

  it 'returns 0 for a nonexistent key' do
    @redises.llen(@key).should == 0
  end

  it 'returns the length of the list' do
    5.times { @redises.lpush(@key, 'X') }
    @redises.llen(@key).should == 5
  end

  it_should_behave_like 'a list-only command'
end
