require 'spec_helper'

describe '#restore(key, ttl, value)' do
  before do
    @key = 'mock-redis-test:45794'
    @src = MockRedis.new
    @src.set(@key, '123')
    @dumped_value = @src.dump(@key)
    @dst = MockRedis.new
    @now = Time.now.round
    Time.stub(:now).and_return(@now)
  end

  it 'allows dump/restoring values between two redis instances' do
    expect(@dst.restore(@key, 0, @dumped_value)).to eq('OK')
    expect(@dst.get(@key)).to eq('123')
    expect(@dst.pttl(@key)).to eq(-1)
  end

  context 'when the key being restored to already exists' do
    before do
      @dst.set(@key, '456')
    end

    it 'raises an error by default' do
      expect { @dst.restore(@key, 0, @dumped_value) }.to raise_error(Redis::CommandError)
      expect(@dst.get(@key)).to eq('456')
    end

    it 'allows replacing the key if replace==true' do
      expect(@dst.restore(@key, 0, @dumped_value, replace: true)).to eq('OK')
      expect(@dst.get(@key)).to eq('123')
    end
  end

  it 'sets ttl in ms' do
    @dst.restore(@key, 500, @dumped_value)
    expect(@dst.pttl(@key)).to eq(500)
  end

  it 'can dump/restore more complex data types' do
    key = 'a_hash'
    @src.mapped_hmset(key, foo: 'bar')
    @dst.restore(key, 0, @src.dump(key))
    expect(@dst.hgetall(key)).to eq('foo' => 'bar')
  end
end
