require 'spec_helper'

describe '#dbsize [mock only]' do
  # mock only since we can't guarantee that the real Redis is empty
  before { @mock = @redises.mock }

  it 'returns 0 for an empty DB' do
    @mock.dbsize.should == 0
  end

  it 'returns the number of keys in the DB' do
    @mock.set('foo', 1)
    @mock.lpush('bar', 2)
    @mock.hset('baz', 3, 4)

    @mock.dbsize.should == 3
  end
end
