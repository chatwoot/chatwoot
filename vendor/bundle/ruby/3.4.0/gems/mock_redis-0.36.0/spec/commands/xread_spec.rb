require 'spec_helper'

describe '#xread(keys, ids)' do
  before :all do
    sleep 1 - (Time.now.to_f % 1)
    @key = 'mock-redis-test:xread'
    @key1 = 'mock-redis-test:xread1'
  end

  it 'reads a single entry' do
    @redises.xadd(@key, { key: 'value' }, id: '1234567891234-0')
    expect(@redises.xread(@key, '0-0'))
      .to eq({ @key => [['1234567891234-0', { 'key' => 'value' }]] })
  end

  it 'reads multiple entries from the beginning of the stream' do
    @redises.xadd(@key, { key0: 'value0' }, id: '1234567891234-0')
    @redises.xadd(@key, { key1: 'value1' }, id: '1234567891234-1')
    expect(@redises.xread(@key, '0-0'))
      .to eq({ @key => [['1234567891234-0', { 'key0' => 'value0' }],
                        ['1234567891234-1', { 'key1' => 'value1' }]] })
  end

  it 'reads entries greater than the ID passed' do
    @redises.xadd(@key, { key0: 'value0' }, id: '1234567891234-0')
    @redises.xadd(@key, { key1: 'value1' }, id: '1234567891234-1')
    expect(@redises.xread(@key, '1234567891234-0'))
      .to eq({ @key => [['1234567891234-1', { 'key1' => 'value1' }]] })
  end

  it 'reads from multiple streams' do
    @redises.xadd(@key, { key: 'value' }, id: '1234567891234-0')
    @redises.xadd(@key1, { key1: 'value1' }, id: '1234567891234-0')
    expect(@redises.xread([@key, @key1], %w[0-0 0-0]))
      .to eq({ @key => [['1234567891234-0', { 'key' => 'value' }]],
               @key1 => [['1234567891234-0', { 'key1' => 'value1' }]] })
  end

  it 'reads from multiple streams at the given IDs' do
    @redises.xadd(@key, { key: 'value0' }, id: '1234567891234-0')
    @redises.xadd(@key, { key: 'value1' }, id: '1234567891234-1')
    @redises.xadd(@key, { key: 'value2' }, id: '1234567891234-2')
    @redises.xadd(@key1, { key1: 'value0' }, id: '1234567891234-0')
    @redises.xadd(@key1, { key1: 'value1' }, id: '1234567891234-1')
    @redises.xadd(@key1, { key1: 'value2' }, id: '1234567891234-2')
    # The first stream won't return anything since we specify the last ID
    expect(@redises.xread([@key, @key1], %w[1234567891234-2 1234567891234-1]))
      .to eq({ @key1 => [['1234567891234-2', { 'key1' => 'value2' }]] })
  end

  it 'supports the block parameter' do
    @redises.xadd(@key, { key: 'value' }, id: '1234567891234-0')
    expect(@redises.xread(@key, '0-0', block: 1000))
      .to eq({ @key => [['1234567891234-0', { 'key' => 'value' }]] })
  end

  it 'limits results with count' do
    @redises.xadd(@key, { key: 'value' }, id: '1234567891234-0')
    @redises.xadd(@key, { key: 'value' }, id: '1234567891234-1')
    @redises.xadd(@key, { key: 'value' }, id: '1234567891234-2')
    expect(@redises.xread(@key, '0-0', count: 1))
      .to eq({ @key => [['1234567891234-0', { 'key' => 'value' }]] })
    expect(@redises.xread(@key, '1234567891234-0', count: 1))
      .to eq({ @key => [['1234567891234-1', { 'key' => 'value' }]] })
  end
end
