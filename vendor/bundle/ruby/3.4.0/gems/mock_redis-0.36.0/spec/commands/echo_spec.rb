require 'spec_helper'

describe '#echo(str)' do
  it 'returns its argument' do
    @redises.echo('foo').should == 'foo'
  end

  it 'stringifies its argument' do
    @redises.echo(1).should == '1'
  end
end
