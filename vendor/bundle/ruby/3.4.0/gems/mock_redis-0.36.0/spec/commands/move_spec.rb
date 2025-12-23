require 'spec_helper'

describe '#move(key, db)' do
  before do
    @srcdb = 0
    @destdb = 1

    @key = 'mock-redis-test:move'
  end

  context 'when key exists in destdb' do
    before do
      @redises.set(@key, 'srcvalue')
      @redises.select(@destdb)
      @redises.set(@key, 'destvalue')
      @redises.select(@srcdb)
    end

    it 'returns false' do
      @redises.move(@key, @destdb).should == false
    end

    it 'leaves destdb/key alone' do
      @redises.select(@destdb)
      @redises.get(@key).should == 'destvalue'
    end

    it 'leaves srcdb/key alone' do
      @redises.get(@key).should == 'srcvalue'
    end
  end

  context 'when key does not exist in srcdb' do
    before do
      @redises.select(@destdb)
      @redises.set(@key, 'destvalue')
      @redises.select(@srcdb)
    end

    it 'returns false' do
      @redises.move(@key, @destdb).should == false
    end

    it 'leaves destdb/key alone' do
      @redises.select(@destdb)
      @redises.get(@key).should == 'destvalue'
    end
  end

  context 'when key exists in the currently-selected DB and not in db' do
    before do
      @redises.set(@key, 'value')
    end

    it 'returns true' do
      @redises.move(@key, @destdb).should == true
    end
  end

  context 'on a string' do
    before do
      @redises.set(@key, 'value')
      @redises.move(@key, @destdb)
    end

    it 'removes key from srcdb' do
      @redises.exists?(@key).should == false
    end

    it 'copies key to destdb' do
      @redises.select(@destdb)
      @redises.get(@key).should == 'value'
    end
  end

  context 'on a list' do
    before do
      @redises.rpush(@key, 'bert')
      @redises.rpush(@key, 'ernie')
      @redises.move(@key, @destdb)
    end

    it 'removes key from srcdb' do
      @redises.exists?(@key).should == false
    end

    it 'copies key to destdb' do
      @redises.select(@destdb)
      @redises.lrange(@key, 0, -1).should == %w[bert ernie]
    end
  end

  context 'on a hash' do
    before do
      @redises.hset(@key, 'a', 1)
      @redises.hset(@key, 'b', 2)

      @redises.move(@key, @destdb)
    end

    it 'removes key from srcdb' do
      @redises.exists?(@key).should == false
    end

    it 'copies key to destdb' do
      @redises.select(@destdb)
      @redises.hgetall(@key).should == { 'a' => '1', 'b' => '2' }
    end
  end

  context 'on a set' do
    before do
      @redises.sadd(@key, 'beer')
      @redises.sadd(@key, 'wine')

      @redises.move(@key, @destdb)
    end

    it 'removes key from srcdb' do
      @redises.exists?(@key).should == false
    end

    it 'copies key to destdb' do
      @redises.select(@destdb)
      @redises.smembers(@key).should == %w[wine beer]
    end
  end

  context 'on a zset' do
    before do
      @redises.zadd(@key, 1, 'beer')
      @redises.zadd(@key, 2, 'wine')

      @redises.move(@key, @destdb)
    end

    it 'removes key from srcdb' do
      @redises.exists?(@key).should == false
    end

    it 'copies key to destdb' do
      @redises.select(@destdb)
      @redises.zrange(@key, 0, -1, :with_scores => true).should ==
        [['beer', 1.0], ['wine', 2.0]]
    end
  end
end
