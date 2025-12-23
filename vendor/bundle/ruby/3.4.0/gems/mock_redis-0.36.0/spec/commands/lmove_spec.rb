require 'spec_helper'

describe '#lmove(source, destination, wherefrom, whereto)' do
  before do
    @list1 = 'mock-redis-test:lmove-list1'
    @list2 = 'mock-redis-test:lmove-list2'

    @redises.lpush(@list1, 'b')
    @redises.lpush(@list1, 'a')

    @redises.lpush(@list2, 'y')
    @redises.lpush(@list2, 'x')
  end

  it 'returns the value moved' do
    @redises.lmove(@list1, @list2, 'left', 'right').should == 'a'
  end

  it "returns nil and doesn't append if source empty" do
    @redises.lmove('empty', @list1, 'left', 'right').should be_nil
    @redises.lrange(@list1, 0, -1).should == %w[a b]
  end

  it 'takes the first element of source and prepends it to destination' do
    @redises.lmove(@list1, @list2, 'left', 'left')

    @redises.lrange(@list1, 0, -1).should == %w[b]
    @redises.lrange(@list2, 0, -1).should == %w[a x y]
  end

  it 'takes the first element of source and appends it to destination' do
    @redises.lmove(@list1, @list2, 'left', 'right')

    @redises.lrange(@list1, 0, -1).should == %w[b]
    @redises.lrange(@list2, 0, -1).should == %w[x y a]
  end

  it 'takes the last element of source and prepends it to destination' do
    @redises.lmove(@list1, @list2, 'right', 'left')

    @redises.lrange(@list1, 0, -1).should == %w[a]
    @redises.lrange(@list2, 0, -1).should == %w[b x y]
  end

  it 'takes the last element of source and appends it to destination' do
    @redises.lmove(@list1, @list2, 'right', 'right')

    @redises.lrange(@list1, 0, -1).should == %w[a]
    @redises.lrange(@list2, 0, -1).should == %w[x y b]
  end

  it 'rotates a list when source and destination are the same' do
    @redises.lmove(@list1, @list1, 'left', 'right')
    @redises.lrange(@list1, 0, -1).should == %w[b a]
  end

  it 'removes empty lists' do
    @redises.llen(@list1).times { @redises.lmove(@list1, @list2, 'left', 'right') }
    @redises.get(@list1).should be_nil
  end

  it 'raises an error for non-list source value' do
    @redises.set(@list1, 'string value')

    lambda do
      @redises.lmove(@list1, @list2, 'left', 'right')
    end.should raise_error(Redis::CommandError)
  end

  let(:default_error) { RedisMultiplexer::MismatchedResponse }
  it_should_behave_like 'a list-only command'
end
