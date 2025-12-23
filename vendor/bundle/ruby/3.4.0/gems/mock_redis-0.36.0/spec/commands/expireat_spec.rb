require 'spec_helper'

describe '#expireat(key, timestamp)' do
  before do
    @key = 'mock-redis-test:expireat'
    @redises.set(@key, 'spork')
  end

  it 'returns true for a key that exists' do
    @redises.expireat(@key, Time.now.to_i + 1).should == true
  end

  it 'returns false for a key that does not exist' do
    @redises.expireat('mock-redis-test:nonesuch', Time.now.to_i + 1).should == false
  end

  it 'removes a key immediately when timestamp is now' do
    @redises.expireat(@key, Time.now.to_i)
    @redises.get(@key).should be_nil
  end

  it "raises an error if you don't give it a Unix timestamp" do
    lambda do
      @redises.expireat(@key, Time.now) # oops, forgot .to_i
    end.should raise_error(Redis::CommandError)
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

    it 'removes keys after enough time has passed' do
      @mock.expireat(@key, @now.to_i + 5)
      Time.stub(:now).and_return(@now + 5)
      @mock.get(@key).should be_nil
    end
  end
end
