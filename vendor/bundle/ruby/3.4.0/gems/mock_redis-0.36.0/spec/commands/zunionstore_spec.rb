require 'spec_helper'

describe '#zunionstore(destination, keys, [:weights => [w,w,], [:aggregate => :sum|:min|:max])' do
  before do
    @set1 = 'mock-redis-test:zunionstore1'
    @set2 = 'mock-redis-test:zunionstore2'
    @set3 = 'mock-redis-test:zunionstore3'
    @dest = 'mock-redis-test:zunionstoredest'

    @redises.zadd(@set1, 1, 'one')

    @redises.zadd(@set2, 1, 'one')
    @redises.zadd(@set2, 2, 'two')

    @redises.zadd(@set3, 1, 'one')
    @redises.zadd(@set3, 2, 'two')
    @redises.zadd(@set3, 3, 'three')
  end

  it 'returns the number of elements in the new set' do
    @redises.zunionstore(@dest, [@set1, @set2, @set3]).should == 3
  end

  it "sums the members' scores by default" do
    @redises.zunionstore(@dest, [@set1, @set2, @set3])
    @redises.zrange(@dest, 0, -1, :with_scores => true).should ==
      [['one', 3.0], ['three', 3.0], ['two', 4.0]]
  end

  it 'removes existing elements in destination' do
    @redises.zadd(@dest, 10, 'ten')

    @redises.zunionstore(@dest, [@set1])
    @redises.zrange(@dest, 0, -1, :with_scores => true).should ==
      [['one', 1.0]]
  end

  it 'raises an error if keys is empty' do
    lambda do
      @redises.zunionstore(@dest, [])
    end.should raise_error(Redis::CommandError)
  end

  context 'when used with a set' do
    before do
      @set4 = 'mock-redis-test:zunionstore4'

      @redises.sadd(@set4, 'two')
      @redises.sadd(@set4, 'three')
      @redises.sadd(@set4, 'four')
    end

    it 'returns the number of elements in the new set' do
      @redises.zunionstore(@dest, [@set3, @set4]).should == 4
    end

    it 'sums the scores, substituting 1.0 for set values' do
      @redises.zunionstore(@dest, [@set3, @set4])
      @redises.zrange(@dest, 0, -1, :with_scores => true).should ==
        [['four', 1.0], ['one', 1.0], ['two', 3.0], ['three', 4.0]]
    end
  end

  context 'when used with a non-coercible structure' do
    before do
      @non_set = 'mock-redis-test:zunionstore4'

      @redises.set(@non_set, 'one')
    end
    it 'raises an error for wrong value type' do
      lambda do
        @redises.zunionstore(@dest, [@set1, @non_set])
      end.should raise_error(Redis::CommandError)
    end
  end

  context 'the :weights argument' do
    it 'multiplies the scores by the weights while aggregating' do
      @redises.zunionstore(@dest, [@set1, @set2, @set3], :weights => [2, 3, 5])
      @redises.zrange(@dest, 0, -1, :with_scores => true).should ==
        [['one', 10.0], ['three', 15.0], ['two', 16.0]]
    end

    it 'raises an error if the number of weights != the number of keys' do
      lambda do
        @redises.zunionstore(@dest, [@set1, @set2, @set3], :weights => [1, 2])
      end.should raise_error(Redis::CommandError)
    end
  end

  context 'the :aggregate argument' do
    before do
      @smalls = 'mock-redis-test:zunionstore:smalls'
      @bigs   = 'mock-redis-test:zunionstore:bigs'

      @redises.zadd(@smalls, 1, 'bert')
      @redises.zadd(@smalls, 2, 'ernie')
      @redises.zadd(@bigs, 100, 'bert')
      @redises.zadd(@bigs, 200, 'ernie')
    end

    it 'aggregates scores with min when :aggregate => :min is specified' do
      @redises.zunionstore(@dest, [@bigs, @smalls], :aggregate => :min)
      @redises.zrange(@dest, 0, -1, :with_scores => true).should ==
        [['bert', 1.0], ['ernie', 2.0]]
    end

    it 'aggregates scores with max when :aggregate => :max is specified' do
      @redises.zunionstore(@dest, [@bigs, @smalls], :aggregate => :max)
      @redises.zrange(@dest, 0, -1, :with_scores => true).should ==
        [['bert', 100.0], ['ernie', 200.0]]
    end

    it 'ignores scores for missing members' do
      @redises.zadd(@smalls, 3, 'grover')
      @redises.zunionstore(@dest, [@bigs, @smalls], :aggregate => :min)
      @redises.zscore(@dest, 'grover').should == 3.0

      @redises.zunionstore(@dest, [@bigs, @smalls], :aggregate => :max)
      @redises.zscore(@dest, 'grover').should == 3.0
    end

    it "allows 'min', 'MIN', etc. as aliases for :min" do
      @redises.zunionstore(@dest, [@bigs, @smalls], :aggregate => 'min')
      @redises.zscore(@dest, 'bert').should == 1.0

      @redises.zunionstore(@dest, [@bigs, @smalls], :aggregate => 'MIN')
      @redises.zscore(@dest, 'bert').should == 1.0
    end

    it 'raises an error for unknown aggregation function' do
      lambda do
        @redises.zunionstore(@dest, [@bigs, @smalls], :aggregate => :mix)
      end.should raise_error(Redis::CommandError)
    end
  end
end
