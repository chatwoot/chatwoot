require 'spec_helper'

describe '#expire(key, seconds)' do
  before do
    @key = 'mock-redis-test:expire'
    @redises.set(@key, 'spork')
  end

  it 'returns true for a key that exists' do
    @redises.expire(@key, 1).should == true
  end

  it 'returns false for a key that does not exist' do
    @redises.expire('mock-redis-test:nonesuch', 1).should == false
  end

  it 'removes a key immediately when seconds==0' do
    @redises.expire(@key, 0)
    @redises.get(@key).should be_nil
  end

  it 'raises an error if seconds is bogus' do
    lambda do
      @redises.expire(@key, 'a couple minutes or so')
    end.should raise_error(Redis::CommandError)
  end

  it 'stringifies key' do
    @redises.expire(@key.to_sym, 9).should == true
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
      @mock.expire(@key, 5)
      Time.stub(:now).and_return(@now + 5)
      @mock.get(@key).should be_nil
    end

    it 'updates an existing expire time' do
      @mock.expire(@key, 5)
      @mock.expire(@key, 6)

      Time.stub(:now).and_return(@now + 5)
      @mock.get(@key).should_not be_nil
    end

    it 'has millisecond precision' do
      @now = Time.at(@now.to_i + 0.5)
      Time.stub(:now).and_return(@now)
      @mock.expire(@key, 5)
      Time.stub(:now).and_return(@now + 4.9)
      @mock.get(@key).should_not be_nil
    end

    context 'expirations on a deleted key' do
      before { @mock.del(@key) }

      it 'cleans up the expiration once the key is gone (string)' do
        @mock.set(@key, 'string')
        @mock.expire(@key, 2)
        @mock.del(@key)
        @mock.set(@key, 'string')

        Time.stub(:now).and_return(@now + 2)

        @mock.get(@key).should_not be_nil
      end

      it 'cleans up the expiration once the key is gone (list)' do
        @mock.rpush(@key, 'coconuts')
        @mock.expire(@key, 2)
        @mock.rpop(@key)

        @mock.rpush(@key, 'coconuts')

        Time.stub(:now).and_return(@now + 2)

        @mock.lindex(@key, 0).should_not be_nil
      end
    end

    context 'with two key expirations' do
      let(:other_key) { 'mock-redis-test:expire-other' }

      before { @redises.set(other_key, 'spork-other') }

      it 'removes keys after enough time has passed' do
        @mock.expire(@key, 5)
        @mock.expire(other_key, 10)

        Time.stub(:now).and_return(@now + 5)
        @mock.get(@key).should be_nil

        Time.stub(:now).and_return(@now + 10)
        @mock.get(other_key).should be_nil
      end
    end
  end
end
