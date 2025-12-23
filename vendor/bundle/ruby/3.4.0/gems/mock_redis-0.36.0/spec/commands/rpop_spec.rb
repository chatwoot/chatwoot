require 'spec_helper'

describe '#rpop(key)' do
  before { @key = 'mock-redis-test:43093' }

  it 'returns and removes the first element of a list' do
    @redises.lpush(@key, 1)
    @redises.lpush(@key, 2)

    @redises.rpop(@key).should == '1'

    @redises.llen(@key).should == 1
  end

  it 'returns nil if the list is empty' do
    @redises.lpush(@key, 'foo')
    @redises.rpop(@key)

    @redises.rpop(@key).should be_nil
  end

  it 'returns nil for nonexistent values' do
    @redises.rpop(@key).should be_nil
  end

  it 'removes empty lists' do
    @redises.lpush(@key, 'foo')
    @redises.rpop(@key)

    @redises.get(@key).should be_nil
  end

  let(:default_error) { RedisMultiplexer::MismatchedResponse }
  it_should_behave_like 'a list-only command'
end
