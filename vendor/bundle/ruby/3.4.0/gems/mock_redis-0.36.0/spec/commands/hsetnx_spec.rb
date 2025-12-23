require 'spec_helper'

describe '#hsetnx(key, field)' do
  before do
    @key = 'mock-redis-test:hsetnx'
  end

  it 'returns true if the field is absent' do
    @redises.hsetnx(@key, 'field', 'val').should == true
  end

  it 'returns 0 if the field is present' do
    @redises.hset(@key, 'field', 'val')
    @redises.hsetnx(@key, 'field', 'val').should == false
  end

  it 'leaves the field unchanged if the field is present' do
    @redises.hset(@key, 'field', 'old')
    @redises.hsetnx(@key, 'field', 'new')
    @redises.hget(@key, 'field').should == 'old'
  end

  it 'sets the field if the field is absent' do
    @redises.hsetnx(@key, 'field', 'new')
    @redises.hget(@key, 'field').should == 'new'
  end

  it 'creates a hash if there is no such field' do
    @redises.hsetnx(@key, 'field', 'val')
    @redises.hget(@key, 'field').should == 'val'
  end

  it 'stores values as strings' do
    @redises.hsetnx(@key, 'num', 1)
    @redises.hget(@key, 'num').should == '1'
  end

  it 'stores fields as strings' do
    @redises.hsetnx(@key, 1, 'one')
    @redises.hget(@key, '1').should == 'one'
  end

  it_should_behave_like 'a hash-only command'
end
