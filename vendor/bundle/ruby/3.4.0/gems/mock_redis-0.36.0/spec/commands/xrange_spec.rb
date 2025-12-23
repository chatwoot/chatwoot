require 'spec_helper'

describe '#xrange("mystream", first: "0-1", last: "0-3", count: 10)' do
  before { @key = 'mock-redis-test:xrange' }

  it 'finds an empty range' do
    expect(@redises.xrange(@key, '-', '+')).to eq []
  end

  it 'finds a single entry with a full range' do
    @redises.xadd(@key, { key: 'value' }, id: '1234567891234-0')
    expect(@redises.xrange(@key, '-', '+'))
      .to eq [['1234567891234-0', { 'key' => 'value' }]]
  end

  it 'finds multiple key/value pairs with a full range' do
    @redises.xadd(@key, { key1: 'value1', key2: 'value2', key3: 'value3' }, id: '1234567891234-0')
    expect(@redises.xrange(@key, '-', '+'))
      .to eq [['1234567891234-0', { 'key1' => 'value1', 'key2' => 'value2', 'key3' => 'value3' }]]
  end

  context 'six items on the list' do
    before :each do
      @redises.xadd(@key, { key1: 'value1' }, id: '1234567891234-0')
      @redises.xadd(@key, { key2: 'value2' }, id: '1234567891245-0')
      @redises.xadd(@key, { key3: 'value3' }, id: '1234567891245-1')
      @redises.xadd(@key, { key4: 'value4' }, id: '1234567891278-0')
      @redises.xadd(@key, { key5: 'value5' }, id: '1234567891278-1')
      @redises.xadd(@key, { key6: 'value6' }, id: '1234567891299-0')
    end

    it 'returns entries in sequential order' do
      expect(@redises.xrange(@key, '-', '+')).to eq(
        [
          ['1234567891234-0', { 'key1' => 'value1' }],
          ['1234567891245-0', { 'key2' => 'value2' }],
          ['1234567891245-1', { 'key3' => 'value3' }],
          ['1234567891278-0', { 'key4' => 'value4' }],
          ['1234567891278-1', { 'key5' => 'value5' }],
          ['1234567891299-0', { 'key6' => 'value6' }]
        ]
      )
    end

    it 'returns entries with a lower limit' do
      expect(@redises.xrange(@key, '1234567891239-0', '+')).to eq(
        [
          ['1234567891245-0', { 'key2' => 'value2' }],
          ['1234567891245-1', { 'key3' => 'value3' }],
          ['1234567891278-0', { 'key4' => 'value4' }],
          ['1234567891278-1', { 'key5' => 'value5' }],
          ['1234567891299-0', { 'key6' => 'value6' }]
        ]
      )
    end

    it 'returns all entries with a lower limit of 0-0' do
      expect(@redises.xrange(@key, '0-0', '+')).to eq(
        [
          ['1234567891234-0', { 'key1' => 'value1' }],
          ['1234567891245-0', { 'key2' => 'value2' }],
          ['1234567891245-1', { 'key3' => 'value3' }],
          ['1234567891278-0', { 'key4' => 'value4' }],
          ['1234567891278-1', { 'key5' => 'value5' }],
          ['1234567891299-0', { 'key6' => 'value6' }]
        ]
      )
    end

    it 'returns entries with an upper limit' do
      expect(@redises.xrange(@key, '-', '1234567891285-0')).to eq(
        [
          ['1234567891234-0', { 'key1' => 'value1' }],
          ['1234567891245-0', { 'key2' => 'value2' }],
          ['1234567891245-1', { 'key3' => 'value3' }],
          ['1234567891278-0', { 'key4' => 'value4' }],
          ['1234567891278-1', { 'key5' => 'value5' }]
        ]
      )
    end

    it 'returns entries with both a lower and an upper limit inclusive' do
      expect(@redises.xrange(@key, '1234567891245-0', '1234567891278-0')).to eq(
        [
          ['1234567891245-0', { 'key2' => 'value2' }],
          ['1234567891245-1', { 'key3' => 'value3' }],
          ['1234567891278-0', { 'key4' => 'value4' }]
        ]
      )
    end

    it 'returns entries with both a lower and an upper limit exclusive' do
      expect(@redises.xrange(@key, '(1234567891245-0', '1234567891285-1')).to eq(
        [
          # We no longer get '1234567891245-0'
          ['1234567891245-1', { 'key3' => 'value3' }],
          ['1234567891278-0', { 'key4' => 'value4' }],
          ['1234567891278-1', { 'key5' => 'value5' }] # Note sequence -1
        ]
      )
    end

    it 'finds the list with sequence numbers' do
      expect(@redises.xrange(@key, '1234567891245-1', '1234567891278-0')).to eq(
        [
          ['1234567891245-1', { 'key3' => 'value3' }],
          ['1234567891278-0', { 'key4' => 'value4' }]
        ]
      )
    end

    it 'finds the list with lower bound without sequence numbers' do
      expect(@redises.xrange(@key, '1234567891245', '+')).to eq(
        [
          ['1234567891245-0', { 'key2' => 'value2' }],
          ['1234567891245-1', { 'key3' => 'value3' }],
          ['1234567891278-0', { 'key4' => 'value4' }],
          ['1234567891278-1', { 'key5' => 'value5' }],
          ['1234567891299-0', { 'key6' => 'value6' }]
        ]
      )
    end

    it 'finds the list with upper bound without sequence numbers' do
      expect(@redises.xrange(@key, '-', '1234567891278')).to eq(
        [
          ['1234567891234-0', { 'key1' => 'value1' }],
          ['1234567891245-0', { 'key2' => 'value2' }],
          ['1234567891245-1', { 'key3' => 'value3' }],
          ['1234567891278-0', { 'key4' => 'value4' }],
          ['1234567891278-1', { 'key5' => 'value5' }]
        ]
      )
    end

    it 'accepts limits as integers' do
      expect(@redises.xrange(@key, 1_234_567_891_245, 1_234_567_891_278)).to eq(
        [
          ['1234567891245-0', { 'key2' => 'value2' }],
          ['1234567891245-1', { 'key3' => 'value3' }],
          ['1234567891278-0', { 'key4' => 'value4' }],
          ['1234567891278-1', { 'key5' => 'value5' }]
        ]
      )
    end

    it 'returns a limited number of items' do
      expect(@redises.xrange(@key, '-', '+', count: 2)).to eq(
        [
          ['1234567891234-0', { 'key1' => 'value1' }],
          ['1234567891245-0', { 'key2' => 'value2' }]
        ]
      )
    end
  end

  it 'raises an invalid stream id error' do
    expect { @redises.xrange(@key, 'X', '+') }
      .to raise_error(
        Redis::CommandError,
        'ERR Invalid stream ID specified as stream command argument'
      )
  end
end
