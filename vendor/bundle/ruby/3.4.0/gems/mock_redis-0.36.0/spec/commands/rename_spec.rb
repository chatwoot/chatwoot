require 'spec_helper'

describe '#rename(key, newkey)' do
  before do
    @key = 'mock-redis-test:rename:key'
    @newkey = 'mock-redis-test:rename:newkey'

    @redises.set(@key, 'oof')
  end

  it 'responds with "OK"' do
    @redises.rename(@key, @newkey).should == 'OK'
  end

  it 'moves the data' do
    @redises.rename(@key, @newkey)
    @redises.get(@newkey).should == 'oof'
  end

  it 'raises an error when the source key is nonexistant' do
    @redises.del(@key)
    lambda do
      @redises.rename(@key, @newkey)
    end.should raise_error(Redis::CommandError)
  end

  it 'responds with "OK" when key == newkey' do
    @redises.rename(@key, @key).should == 'OK'
  end

  it 'overwrites any existing value at newkey' do
    @redises.set(@newkey, 'rab')
    @redises.rename(@key, @newkey)
    @redises.get(@newkey).should == 'oof'
  end

  it 'keeps expiration' do
    @redises.expire(@key, 1000)
    @redises.rename(@key, @newkey)
    @redises.ttl(@newkey).should be > 0
  end
end
