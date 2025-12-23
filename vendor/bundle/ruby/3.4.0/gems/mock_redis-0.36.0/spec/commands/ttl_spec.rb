require 'spec_helper'

describe '#ttl(key)' do
  before do
    @key = 'mock-redis-test:persist'
    @redises.set(@key, 'spork')
  end

  it 'returns -1 for a key with no expiration' do
    @redises.ttl(@key).should == -1
  end

  it 'returns -2 for a key that does not exist' do
    @redises.ttl('mock-redis-test:nonesuch').should == -2
  end

  it 'stringifies key' do
    @redises.expire(@key, 9)
    @redises.ttl(@key.to_sym).should > 0
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

    it "gives you the key's remaining lifespan in seconds" do
      @mock.expire(@key, 5)
      @mock.ttl(@key).should == 5
    end
  end
end
