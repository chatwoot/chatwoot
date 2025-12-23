require 'spec_helper'

describe '#bgrewriteaof [mock only]' do
  it 'just returns a canned string' do
    @redises.mock.bgrewriteaof.should =~ /append/
  end
end
