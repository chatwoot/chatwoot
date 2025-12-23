require 'spec_helper'

describe '#mapped_mset(hash)' do
  before do
    @key1 = 'mock-redis-test:a'
    @key2 = 'mock-redis-test:b'
    @key3 = 'mock-redis-test:c'

    @redises.set(@key1, '1')
    @redises.set(@key2, '2')
  end

  it 'sets the values properly' do
    @redises.mapped_mset(@key1 => 'one', @key3 => 'three').should eq('OK')
    @redises.get(@key1).should eq('one')
    @redises.get(@key2).should eq('2') # left alone
    @redises.get(@key3).should eq('three')
  end
end
