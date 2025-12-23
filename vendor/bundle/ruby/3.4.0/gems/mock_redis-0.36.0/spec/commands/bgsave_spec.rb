require 'spec_helper'

describe '#bgsave [mock only]' do
  it 'just returns a canned string' do
    @redises.mock.bgsave.should =~ /saving/
  end
end
