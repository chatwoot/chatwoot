require 'spec_helper'

describe '#psetex(key, miliseconds, value)' do
  before { @key = 'mock-redis-test:setex' }

  it "responds with 'OK'" do
    @redises.psetex(@key, 10, 'value').should == 'OK'
  end

  it 'sets the value' do
    @redises.psetex(@key, 10_000, 'value')
    @redises.get(@key).should == 'value'
  end

  it 'sets the expiration time' do
    @redises.psetex(@key, 10_000, 'value')

    # no guarantee these are the same
    @redises.real.ttl(@key).should > 0
    @redises.mock.ttl(@key).should > 0
  end

  it 'converts time correctly' do
    @redises.psetex(@key, 10_000_000, 'value')

    @redises.mock.ttl(@key).should > 9_000
  end

  context 'when expiration time is zero' do
    it 'raises Redis::CommandError' do
      expect do
        @redises.psetex(@key, 0, 'value')
      end.to raise_error(Redis::CommandError, 'ERR invalid expire time in psetex')
    end
  end

  context 'when expiration time is negative' do
    it 'raises Redis::CommandError' do
      expect do
        @redises.psetex(@key, -2, 'value')
      end.to raise_error(Redis::CommandError, 'ERR invalid expire time in psetex')
    end
  end
end
