require 'spec_helper'

describe '#lpop(key)' do
  before { @key = 'mock-redis-test:65374' }

  it 'returns and removes the first element of a list' do
    @redises.lpush(@key, 1)
    @redises.lpush(@key, 2)

    @redises.lpop(@key).should == '2'

    @redises.llen(@key).should == 1
  end

  it 'returns nil if the list is empty' do
    @redises.lpush(@key, 'foo')
    @redises.lpop(@key)

    @redises.lpop(@key).should be_nil
  end

  it 'returns nil for nonexistent values' do
    @redises.lpop(@key).should be_nil
  end

  it 'removes empty lists' do
    @redises.lpush(@key, 'foo')
    @redises.lpop(@key)

    @redises.get(@key).should be_nil
  end

  let(:default_error) { RedisMultiplexer::MismatchedResponse }
  it_should_behave_like 'a list-only command'
end
