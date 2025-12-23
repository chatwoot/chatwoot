require 'spec_helper'

describe '#hgetall(key)' do
  before do
    @key = 'mock-redis-test:hgetall'
    @redises.hset(@key, 'k1', 'v1')
    @redises.hset(@key, 'k2', 'v2')
  end

  it 'returns the (key, value) pairs stored in the hash' do
    @redises.hgetall(@key).should == {
      'k1' => 'v1',
      'k2' => 'v2',
    }
  end

  it 'returns [] when there is no such key' do
    @redises.hgetall('mock-redis-test:nonesuch').should == {}
  end

  it "doesn't return a mutable reference to the returned data" do
    mr = MockRedis.new
    mr.hset(@key, 'k1', 'v1')
    mr.hset(@key, 'k2', 'v2')
    hash = mr.hgetall(@key)
    hash['dont'] = 'mutate'
    new_hash = mr.hgetall(@key)
    new_hash.keys.sort.should == %w[k1 k2]
  end

  it_should_behave_like 'a hash-only command'
end
