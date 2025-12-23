require 'spec_helper'

describe '#eval(*)' do
  it 'returns nothing' do
    @redises.eval('return nil').should be_nil
  end
end
