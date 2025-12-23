require 'spec_helper'

describe '#persist(key)' do
  before do
    @key = 'mock-redis-test:persist'
    @redises.set(@key, 'spork')
  end

  it 'returns true for a key with a timeout' do
    @redises.expire(@key, 10_000)
    @redises.persist(@key).should == true
  end

  it 'returns false for a key with no timeout' do
    @redises.persist(@key).should == false
  end

  it 'returns false for a key that does not exist' do
    @redises.persist('mock-redis-test:nonesuch').should == false
  end

  it 'removes the timeout' do
    @redises.expire(@key, 10_000)
    @redises.persist(@key)
    @redises.persist(@key).should == false
  end

  context '[mock only]' do
    # These are mock-only since we can't actually manipulate time in
    # the real Redis.

    before(:all) do
      @mock = @redises.mock
    end

    before do
      @now = Time.now
      Time.stub(:now).and_return(@now)
    end

    it 'makes keys stay around' do
      @mock.expire(@key, 5)
      @mock.persist(@key)
      Time.stub(:now).and_return(@now + 5)
      @mock.get(@key).should_not be_nil
    end
  end
end
