require 'spec_helper'

describe '#set(key, value)' do
  let(:key) { 'mock-redis-test' }

  it "responds with 'OK'" do
    @redises.set('mock-redis-test', 1).should == 'OK'
  end

  context 'options' do
    it 'raises an error for EX seconds = 0' do
      expect do
        @redises.set('mock-redis-test', 1, ex: 0)
      end.to raise_error(Redis::CommandError, 'ERR invalid expire time in set')
    end

    it 'raises an error for PX milliseconds = 0' do
      expect do
        @redises.set('mock-redis-test', 1, px: 0)
      end.to raise_error(Redis::CommandError, 'ERR invalid expire time in set')
    end

    it 'accepts NX' do
      @redises.del(key)
      @redises.set(key, 1, nx: true).should == true
      @redises.set(key, 1, nx: true).should == false
    end

    it 'accepts XX' do
      @redises.del(key)
      @redises.set(key, 1, xx: true).should == false
      @redises.set(key, 1).should == 'OK'
      @redises.set(key, 1, xx: true).should == true
    end

    it 'accepts GET on a string' do
      @redises.set(key, '1').should == 'OK'
      @redises.set(key, '2', get: true).should == '1'
      @redises.set(key, '3', get: true).should == '2'
    end

    context 'when set key is not a String' do
      it 'should error with Redis::CommandError' do
        @redises.lpush(key, '1').should == 1
        expect do
          @redises.set(key, '2', get: true)
        end.to raise_error(Redis::CommandError)
      end
    end

    it 'sets the ttl to -1' do
      @redises.set(key, 1)
      expect(@redises.ttl(key)).to eq(-1)
    end

    context 'with an expiry time' do
      before :each do
        Timecop.freeze
        @redises.set(key, 1, ex: 90)
      end

      after :each do
        @redises.del(key)
        Timecop.return
      end

      it 'has the TTL set' do
        expect(@redises.ttl(key)).to eq 90
      end

      it 'resets the TTL without keepttl' do
        expect do
          @redises.set(key, 2)
        end.to change { @redises.ttl(key) }.from(90).to(-1)
      end

      it 'does not change the TTL with keepttl: true' do
        expect do
          @redises.set(key, 2, keepttl: true)
        end.not_to change { @redises.ttl(key) }.from(90)
      end
    end

    it 'accepts KEEPTTL' do
      expect(@redises.set(key, 1, keepttl: true)).to eq 'OK'
    end

    it 'does not set TTL without ex' do
      @redises.set(key, 1)
      expect(@redises.ttl(key)).to eq(-1)
    end

    it 'sets the TTL' do
      Timecop.freeze do
        @redises.set(key, 1, ex: 90)
        expect(@redises.ttl(key)).to eq 90
      end
    end

    it 'raises on unknown options' do
      @redises.del(key)
      expect do
        @redises.set(key, 1, logger: :something)
      end.to raise_error(ArgumentError, /unknown keyword/)
    end

    context '[mock only]' do
      before(:all) do
        @mock = @redises.mock
      end

      before do
        @now = Time.now
        Time.stub(:now).and_return(@now)
      end

      it 'accepts EX seconds' do
        @mock.set(key, 1, ex: 1).should == 'OK'
        @mock.get(key).should_not be_nil
        Time.stub(:now).and_return(@now + 2)
        @mock.get(key).should be_nil
      end

      it 'accepts PX milliseconds' do
        @mock.set(key, 1, px: 500).should == 'OK'
        @mock.get(key).should_not be_nil
        Time.stub(:now).and_return(@now + 300 / 1000.to_f)
        @mock.get(key).should_not be_nil
        Time.stub(:now).and_return(@now + 600 / 1000.to_f)
        @mock.get(key).should be_nil
      end
    end
  end
end
