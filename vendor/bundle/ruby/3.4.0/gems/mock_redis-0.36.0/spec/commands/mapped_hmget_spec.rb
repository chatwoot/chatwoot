require 'spec_helper'

describe '#mapped_hmget(key, *fields)' do
  before do
    @key = 'mock-redis-test:mapped_hmget'
    @redises.hmset(@key, 'k1', 'v1', 'k2', 'v2')
  end

  it 'returns values stored at key' do
    @redises.mapped_hmget(@key, 'k1', 'k2').should == { 'k1' => 'v1', 'k2' => 'v2' }
  end

  it 'returns nils for missing fields' do
    @redises.mapped_hmget(@key, 'k1', 'mock-redis-test:nonesuch').
      should == { 'k1' => 'v1', 'mock-redis-test:nonesuch' => nil }
  end

  it 'treats an array as the first key' do
    @redises.mapped_hmget(@key, %w[k1 k2]).should == { %w[k1 k2] => 'v1' }
  end

  it 'raises an error if given no fields' do
    lambda do
      @redises.mapped_hmget(@key)
    end.should raise_error(Redis::CommandError)
  end

  it_should_behave_like 'a hash-only command'
end
