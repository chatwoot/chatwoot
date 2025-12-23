require 'spec_helper'

describe '#zrank(key, member)' do
  before do
    @key = 'mock-redis-test:zrank'

    @redises.zadd(@key, 1, 'one')
    @redises.zadd(@key, 2, 'two')
    @redises.zadd(@key, 3, 'three')
  end

  it "returns nil if member wasn't present in the set" do
    @redises.zrank(@key, 'foo').should be_nil
  end

  it 'returns the index of the member in the set' do
    @redises.zrank(@key, 'one').should == 0
    @redises.zrank(@key, 'two').should == 1
    @redises.zrank(@key, 'three').should == 2
  end

  it 'handles integer members correctly' do
    member = 11
    @redises.zadd(@key, 4, member)
    @redises.zrank(@key, member).should == 3
  end

  it_should_behave_like 'a zset-only command'
end
