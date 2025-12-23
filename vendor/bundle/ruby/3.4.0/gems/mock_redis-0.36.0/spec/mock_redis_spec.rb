require 'spec_helper'

describe MockRedis do
  let(:url) { 'redis://127.0.0.1:6379/1' }

  describe '.new' do
    subject { MockRedis.new(:url => url) }

    it 'correctly parses options' do
      subject.host.should == '127.0.0.1'
      subject.port.should == 6379
      subject.db.should == 1
    end

    its(:id) { should == url }

    its(:location) { should == url }
  end

  describe '.connect' do
    let(:url) { 'redis://127.0.0.1:6379/0' }
    subject { MockRedis.connect(:url => url) }

    it 'correctly parses options' do
      subject.host.should == '127.0.0.1'
      subject.port.should == 6379
      subject.db.should == 0
    end

    its(:id) { should == url }
  end

  describe 'Injecting a time class' do
    describe '.options' do
      let(:time_stub) { double 'Time' }
      let(:options)   { { :time_class => time_stub } }

      it 'defaults to Time' do
        mock_redis = MockRedis.new

        mock_redis.options[:time_class].should == Time
      end

      it 'has a configurable Time class' do
        mock_redis = MockRedis.new(options)

        mock_redis.options[:time_class].should == time_stub
      end
    end

    describe '.now' do
      let(:time_stub) { double 'Time', :now => Time.new(2019, 1, 2, 3, 4, 6, '+00:00') }
      let(:options)   { { :time_class => time_stub } }

      subject { MockRedis.new(options) }

      its(:now) { should == [1_546_398_246, 0] }
    end

    describe '.time' do
      let(:time_stub) { double 'Time', :now => Time.new(2019, 1, 2, 3, 4, 6, '+00:00') }
      let(:options)   { { :time_class => time_stub } }

      subject { MockRedis.new(options) }

      its(:time) { should == [1_546_398_246, 0] }
    end

    describe '.expireat' do
      let(:time_at)   { 'expireat' }
      let(:time_stub) { double 'Time' }
      let(:options)   { { :time_class => time_stub } }
      let(:timestamp) { 123_456 }

      subject { MockRedis.new(options) }

      it 'Forwards time_at to the time_class' do
        time_stub.should_receive(:at).with(timestamp).and_return(time_at)

        subject.time_at(timestamp).should == time_at
      end
    end
  end

  describe 'supplying a logger' do
    it 'logs redis commands' do
      logger = double('Logger', debug?: true, debug: nil)
      mock_redis = MockRedis.new(logger: logger)
      expect(logger).to receive(:debug).with(/command=HMGET args="hash" "key1" "key2"/)
      mock_redis.hmget('hash', 'key1', 'key2')
    end
  end
end
