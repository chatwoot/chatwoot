require 'spec_helper'

describe '#lastsave [mock only]' do
  # can't test against both since it's timing-dependent
  it 'returns a Unix time' do
    @redises.mock.lastsave.to_s.should =~ /^\d+$/
  end
end
