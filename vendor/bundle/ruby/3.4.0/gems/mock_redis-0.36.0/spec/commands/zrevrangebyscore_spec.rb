require 'spec_helper'

describe '#zrevrangebyscore(key, start, stop [:with_scores => true] [:limit => [offset count]])' do
  before do
    @key = 'mock-redis-test:zrevrangebyscore'
    @redises.zadd(@key, 1, 'Washington')
    @redises.zadd(@key, 2, 'Adams')
    @redises.zadd(@key, 3, 'Jefferson')
    @redises.zadd(@key, 4, 'Madison')
  end

  context 'when the zset is empty' do
    before do
      @redises.del(@key)
    end

    it 'should return an empty array' do
      @redises.exists?(@key).should == false
      @redises.zrevrangebyscore(@key, 0, 4).should == []
    end
  end

  it 'returns the elements in order by score' do
    @redises.zrevrangebyscore(@key, 4, 3).should == %w[Madison Jefferson]
  end

  it 'returns the scores when :with_scores is specified' do
    @redises.zrevrangebyscore(@key, 4, 3, :with_scores => true).
      should == [['Madison', 4.0], ['Jefferson', 3.0]]
  end

  it 'returns the scores when :withscores is specified' do
    @redises.zrevrangebyscore(@key, 4, 3, :withscores => true).
      should == [['Madison', 4.0], ['Jefferson', 3.0]]
  end

  it 'treats +inf as positive infinity' do
    @redises.zrevrangebyscore(@key, '+inf', 3).
      should == %w[Madison Jefferson]
  end

  it 'honors the :limit => [offset count] argument' do
    @redises.zrevrangebyscore(@key, 100, -100, :limit => [1, 2]).
      should == %w[Jefferson Adams]
  end

  it "raises an error if :limit isn't a 2-tuple" do
    lambda do
      @redises.zrevrangebyscore(@key, 100, -100, :limit => [1, 2, 3])
    end.should raise_error(Redis::CommandError)

    lambda do
      @redises.zrevrangebyscore(@key, 100, -100, :limit => '1, 2')
    end.should raise_error(RedisMultiplexer::MismatchedResponse)
  end

  it_should_behave_like 'a zset-only command'
end
