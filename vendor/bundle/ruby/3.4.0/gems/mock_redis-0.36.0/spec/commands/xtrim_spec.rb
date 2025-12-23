require 'spec_helper'

describe '#xtrim("mystream", 1000, approximate: true)' do
  before { @key = 'mock-redis-test:xtrim' }

  before :each do
    @redises.xadd(@key, { key1: 'value1' }, id: '1234567891234-0')
    @redises.xadd(@key, { key2: 'value2' }, id: '1234567891245-0')
    @redises.xadd(@key, { key3: 'value3' }, id: '1234567891245-1')
    @redises.xadd(@key, { key4: 'value4' }, id: '1234567891278-0')
    @redises.xadd(@key, { key5: 'value5' }, id: '1234567891278-1')
    @redises.xadd(@key, { key6: 'value6' }, id: '1234567891299-0')
  end

  it 'returns the number of elements deleted' do
    expect(@redises.xtrim(@key, 4)).to eq 2
  end

  it 'returns 0 if count is greater than size' do
    initial = @redises.xrange(@key, '-', '+')
    expect(@redises.xtrim(@key, 1000)).to eq 0
    expect(@redises.xrange(@key, '-', '+')).to eql(initial)
  end

  it 'deletes the oldes elements' do
    @redises.xtrim(@key, 4)
    expect(@redises.xrange(@key, '-', '+')).to eq(
      [
        ['1234567891245-1', { 'key3' => 'value3' }],
        ['1234567891278-0', { 'key4' => 'value4' }],
        ['1234567891278-1', { 'key5' => 'value5' }],
        ['1234567891299-0', { 'key6' => 'value6' }]
      ]
    )
  end
end
