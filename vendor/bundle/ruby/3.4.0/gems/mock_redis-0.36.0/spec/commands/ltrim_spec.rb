require 'spec_helper'

describe '#ltrim(key, start, stop)' do
  before do
    @key = 'mock-redis-test:22310'

    %w[v0 v1 v2 v3 v4].reverse_each { |v| @redises.lpush(@key, v) }
  end

  it "returns 'OK'" do
    @redises.ltrim(@key, 1, 3).should == 'OK'
  end

  it 'trims the list to include only the specified elements' do
    @redises.ltrim(@key, 1, 3)
    @redises.lrange(@key, 0, -1).should == %w[v1 v2 v3]
  end

  it 'trims the list when start and stop are strings' do
    @redises.ltrim(@key, '1', '3')
    @redises.lrange(@key, 0, -1).should == %w[v1 v2 v3]
  end

  it 'trims the list to include only the specified elements (negative indices)' do
    @redises.ltrim(@key, -2, -1)
    @redises.lrange(@key, 0, -1).should == %w[v3 v4]
  end

  it 'trims the list to include only the specified elements (out of range negative indices)' do
    @redises.ltrim(@key, -10, -2)
    @redises.lrange(@key, 0, -1).should == %w[v0 v1 v2 v3]
  end

  it 'does not crash on overly-large indices' do
    @redises.ltrim(@key, 100, 200)
    @redises.lrange(@key, 0, -1).should == %w[]
  end

  it 'removes empty lists' do
    @redises.ltrim(@key, 1, 0)
    @redises.get(@key).should be_nil
  end

  it_should_behave_like 'a list-only command'
end
