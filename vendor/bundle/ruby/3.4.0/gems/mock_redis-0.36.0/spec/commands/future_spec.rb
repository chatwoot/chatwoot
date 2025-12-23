require 'spec_helper'

describe MockRedis::Future do
  let(:command) { [:get, 'foo'] }
  let(:result)  { 'bar' }
  let(:block)   { ->(value) { value.upcase } }

  before do
    @future = MockRedis::Future.new(command)
    @future2 = MockRedis::Future.new(command, block)
  end

  it 'remembers the command' do
    @future.command.should eq(command)
  end

  it 'raises an error if the value is requested before the result is set' do
    expect { @future.value }.to raise_error(MockRedis::FutureNotReady)
  end

  it 'returns the value after the result has been set' do
    @future.store_result(result)
    @future.value.should eq(result)
  end

  it 'executes the block on the value if block is passed in' do
    @future2.store_result(result)
    @future2.value.should eq('BAR')
  end
end
