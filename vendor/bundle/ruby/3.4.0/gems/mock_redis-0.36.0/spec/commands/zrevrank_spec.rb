require 'spec_helper'

describe '#zrevrank(key, member)' do
  before do
    @key = 'mock-redis-test:zrevrank'

    @redises.zadd(@key, 1, 'one')
    @redises.zadd(@key, 2, 'two')
    @redises.zadd(@key, 3, 'three')
  end

  it "returns nil if member wasn't present in the set" do
    @redises.zrevrank(@key, 'foo').should be_nil
  end

  it 'returns the index of the member in the set (ordered by -score)' do
    @redises.zrevrank(@key, 'one').should == 2
    @redises.zrevrank(@key, 'two').should == 1
    @redises.zrevrank(@key, 'three').should == 0
  end

  it 'handles integer members correctly' do
    member = 11
    @redises.zadd(@key, 4, member)
    @redises.zrevrank(@key, member).should == 0
  end

  it_should_behave_like 'a zset-only command'
end
