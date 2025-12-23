require 'spec_helper'

describe '#pexpire(key, ms)' do
  before do
    @key = 'mock-redis-test:pexpire'
    @redises.set(@key, 'spork')
  end

  it 'returns true for a key that exists' do
    @redises.pexpire(@key, 1).should == true
  end

  it 'returns false for a key that does not exist' do
    @redises.pexpire('mock-redis-test:nonesuch', 1).should == false
  end

  it 'removes a key immediately when ms==0' do
    @redises.pexpire(@key, 0)
    @redises.get(@key).should be_nil
  end

  it 'raises an error if ms is bogus' do
    lambda do
      @redises.pexpire(@key, 'a couple minutes or so')
    end.should raise_error(Redis::CommandError)
  end

  it 'stringifies key' do
    @redises.pexpire(@key.to_sym, 9).should == true
  end

  context '[mock only]' do
    # These are mock-only since we can't actually manipulate time in
    # the real Redis.

    before(:all) do
      @mock = @redises.mock
    end

    before do
      @now = Time.now.round
      Time.stub(:now).and_return(@now)
    end

    it 'removes keys after enough time has passed' do
      @mock.pexpire(@key, 5)
      Time.stub(:now).and_return(@now + Rational(6, 1000))
      @mock.get(@key).should be_nil
    end

    it 'updates an existing pexpire time' do
      @mock.pexpire(@key, 5)
      @mock.pexpire(@key, 6)

      Time.stub(:now).and_return(@now + Rational(5, 1000))
      @mock.get(@key).should_not be_nil
    end

    context 'expirations on a deleted key' do
      before { @mock.del(@key) }

      it 'cleans up the expiration once the key is gone (string)' do
        @mock.set(@key, 'string')
        @mock.pexpire(@key, 2)
        @mock.del(@key)
        @mock.set(@key, 'string')

        Time.stub(:now).and_return(@now + 0.003)

        @mock.get(@key).should_not be_nil
      end

      it 'cleans up the expiration once the key is gone (list)' do
        @mock.rpush(@key, 'coconuts')
        @mock.pexpire(@key, 2)
        @mock.rpop(@key)

        @mock.rpush(@key, 'coconuts')

        Time.stub(:now).and_return(@now + 0.003)

        @mock.lindex(@key, 0).should_not be_nil
      end
    end
  end
end
