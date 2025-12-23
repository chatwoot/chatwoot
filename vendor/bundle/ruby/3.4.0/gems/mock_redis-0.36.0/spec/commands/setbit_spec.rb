require 'spec_helper'

describe '#setbit(key, offset)' do
  before do
    Encoding.default_external = 'UTF-8'
    @key = 'mock-redis-test:setbit'
    @redises.set(@key, 'h') # ASCII 0x68
  end

  it "returns the original stored bit's value" do
    @redises.setbit(@key, 0, 1).should == 0
    @redises.setbit(@key, 1, 1).should == 1
  end

  it 'sets the bit within the string' do
    @redises.setbit(@key, 7, 1)
    @redises.get(@key).should == 'i'  # ASCII 0x69
  end

  it 'unsets the bit within the string' do
    @redises.setbit(@key, 1, 0)
    @redises.get(@key).should == '('  # ASCII 0x28
  end

  it 'does the right thing with multibyte characters' do
    @redises.set(@key, '€99.94') # the euro sign is 3 bytes wide in UTF-8
    @redises.setbit(@key, 63, 1).should == 0
    @redises.get(@key).should == '€99.95'
  end

  it 'expands the string if necessary' do
    @redises.setbit(@key, 9, 1)
    @redises.get(@key).should == 'h@'
  end

  it 'sets added bits to 0' do
    @redises.setbit(@key, 17, 1)
    @redises.get(@key).should == "h\000@"
  end

  it 'treats missing keys as empty strings' do
    @redises.del(@key)
    @redises.setbit(@key, 1, 1)
    @redises.get(@key).should == '@'
  end

  it 'sets and retrieves bits' do
    @redises.setbit(@key, 22, 1)
    @redises.getbit(@key, 22).should == 1
    @redises.setbit(@key, 23, 0)
    @redises.getbit(@key, 23).should == 0
  end

  it_should_behave_like 'a string-only command'
end
