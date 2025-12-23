require 'spec_helper'

describe '#srandmember(key)' do
  before do
    @key = 'mock-redis-test:srandmember'

    @redises.sadd(@key, 'value')
  end

  it 'returns a member of the set' do
    @redises.srandmember(@key).should == 'value'
  end

  it 'does not modify the set' do
    @redises.srandmember(@key)
    @redises.smembers(@key).should == ['value']
  end

  it 'returns nil if the set is empty' do
    @redises.spop(@key)
    @redises.srandmember(@key).should be_nil
  end

  context 'when count argument is specified' do
    before do
      @redises.sadd(@key, 'value2')
      @redises.sadd(@key, 'value3')
    end

    # NOTE: We disable result checking since MockRedis and Redis will likely
    # return a different random set (since the selection is, well, random)
    it 'returns the whole set if count is greater than the set size' do
      @redises.send_without_checking(:srandmember, @key, 5).should =~ %w[value value2 value3]
    end

    it 'returns random members up to count from the set when count is smaller than the set size' do
      @redises.send_without_checking(:srandmember, @key, 2).size.should == 2
    end

    it 'returns random members up to count from the set when count is negative even if count.abs is greater than the set size' do # rubocop:disable Layout/LineLength
      @redises.send_without_checking(:srandmember, @key, -5).size.should == 5
    end

    it 'returns nil if the set is empty' do
      @redises.srem(@key, %w[value value2 value3])
      @redises.srandmember(@key, 2).should be_empty
    end
  end
end
