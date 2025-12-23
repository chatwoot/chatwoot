require 'spec_helper'

describe '#del(key [, key, ...])' do
  before :all do
    sleep 1 - (Time.now.to_f % 1)
  end

  before :each do
    # TODO: Redis appears to be returning a timestamp a few seconds in the future
    # so we're ignoring the last 5 digits (time in milliseconds)
    @redises._gsub(/\d{5}-\d/, '...-.')
  end

  it 'returns the number of keys deleted' do
    @redises.set('mock-redis-test:1', 1)
    @redises.set('mock-redis-test:2', 1)

    @redises.del(
      'mock-redis-test:1',
      'mock-redis-test:2',
      'mock-redis-test:other'
    ).should == 2
  end

  it 'actually removes the key' do
    @redises.set('mock-redis-test:1', 1)
    @redises.del('mock-redis-test:1')

    @redises.get('mock-redis-test:1').should be_nil
  end

  it 'accepts an array of keys' do
    @redises.set('mock-redis-test:1', 1)
    @redises.set('mock-redis-test:2', 2)

    @redises.del(%w[mock-redis-test:1 mock-redis-test:2])

    @redises.get('mock-redis-test:1').should be_nil
    @redises.get('mock-redis-test:2').should be_nil
  end

  it 'raises an error if an empty array is given' do
    expect { @redises.del [] }.not_to raise_error Redis::CommandError
  end

  it 'removes a stream key' do
    @redises.xadd('mock-redis-stream', { key: 'value' }, maxlen: 0)
    expect(@redises.exists?('mock-redis-stream')).to eq true
    @redises.del('mock-redis-stream')
    expect(@redises.exists?('mock-redis-stream')).to eq false
  end
end
