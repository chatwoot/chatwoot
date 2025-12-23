require 'spec_helper'

describe '#sort(key, options)' do
  before do
    @key = 'mock-redis-test:zset_sort'

    @redises.zadd(@key, 100, '1')
    @redises.zadd(@key, 99, '2')

    @redises.set('mock-redis-test:values_1', 'a')
    @redises.set('mock-redis-test:values_2', 'b')

    @redises.set('mock-redis-test:weight_1', '2')
    @redises.set('mock-redis-test:weight_2', '1')

    @redises.hset('mock-redis-test:hash_1', 'key', 'x')
    @redises.hset('mock-redis-test:hash_2', 'key', 'y')
  end

  it_should_behave_like 'a sortable'
end
