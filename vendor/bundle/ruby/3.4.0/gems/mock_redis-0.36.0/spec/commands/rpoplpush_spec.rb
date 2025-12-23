require 'spec_helper'

describe '#rpoplpush(source, destination)' do
  before do
    @list1 = 'mock-redis-test:rpoplpush-list1'
    @list2 = 'mock-redis-test:rpoplpush-list2'

    @redises.lpush(@list1, 'b')
    @redises.lpush(@list1, 'a')

    @redises.lpush(@list2, 'y')
    @redises.lpush(@list2, 'x')
  end

  it 'returns the value moved' do
    @redises.rpoplpush(@list1, @list2).should == 'b'
  end

  it "returns false and doesn't append if source empty" do
    @redises.rpoplpush('empty', @list1).should be_nil
    @redises.lrange(@list1, 0, -1).should == %w[a b]
  end

  it 'takes the last element of destination and prepends it to source' do
    @redises.rpoplpush(@list1, @list2)

    @redises.lrange(@list1, 0, -1).should == %w[a]
    @redises.lrange(@list2, 0, -1).should == %w[b x y]
  end

  it 'rotates a list when source and destination are the same' do
    @redises.rpoplpush(@list1, @list1)
    @redises.lrange(@list1, 0, -1).should == %w[b a]
  end

  it 'removes empty lists' do
    @redises.llen(@list1).times { @redises.rpoplpush(@list1, @list2) }
    @redises.get(@list1).should be_nil
  end

  it 'raises an error for non-list source value' do
    @redises.set(@list1, 'string value')

    lambda do
      @redises.rpoplpush(@list1, @list2)
    end.should raise_error(Redis::CommandError)
  end

  it_should_behave_like 'a list-only command'
end
