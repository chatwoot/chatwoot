require 'spec_helper'

describe '#pipelined' do
  it 'yields to its block' do
    res = false
    @redises.pipelined do
      res = true
    end
    res.should == true
  end

  context 'with a few added data' do
    let(:key1)   { 'hello' }
    let(:key2)   { 'world' }
    let(:value1) { 'foo' }
    let(:value2) { 'bar' }

    before do
      @redises.set key1, value1
      @redises.set key2, value2
    end

    it 'returns results of pipelined operations' do
      results = @redises.pipelined do |redis|
        redis.get key1
        redis.get key2
      end

      results.should == [value1, value2]
    end

    it 'returns futures' do
      future = nil

      @redises.mock.pipelined do |redis|
        future = redis.get key1
      end

      future.class.should be MockRedis::Future
    end
  end

  context 'with pipelined operations returning array replies' do
    let(:key1) { 'colors' }
    let(:key2) { 'seasons' }
    let(:value1) { %w[blue yellow] }
    let(:value2) { %w[summer winter] }

    before do
      @redises.rpush(key1, value1)
      @redises.rpush(key2, value2)
    end

    after do
      @redises.del key1
      @redises.del key2
    end

    it 'returns an array of the array replies' do
      results = @redises.pipelined do |_redis|
        @redises.lrange(key1, 0, -1)
        @redises.lrange(key2, 0, -1)
      end

      results.should == [value1, value2]
    end
  end

  context 'with redis time return value' do
    let(:time_stub) { double 'Time', :now => Time.new(2019, 1, 2, 3, 4, 6, '+00:00') }
    let(:options)   { { :time_class => time_stub } }

    subject { MockRedis.new(options) }

    it 'returns the time value' do
      subject.set('foo', 'bar')

      results = subject.pipelined do
        subject.get('foo')
        subject.host # defined on MockRedis, so not captured
        subject.time
        subject.echo('baz')
      end

      expect(results).to eq(['bar', [1_546_398_246, 0], 'baz'])
    end
  end

  context 'with nested pipelines' do
    let(:key1)   { 'hello' }
    let(:key2)   { 'world' }
    let(:value1) { 'foo' }
    let(:value2) { 'bar' }

    before do
      @redises.set key1, value1
      @redises.set key2, value2
    end

    it 'returns results of the nested pipelines' do
      results = @redises.pipelined do |pr1|
        pr1.pipelined do |pr2|
          pr2.get key1
        end

        pr1.pipelined do |pr2|
          pr2.get key2
        end
      end

      results.should == [value1, value2]
    end
  end
end
