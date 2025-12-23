require 'spec_helper'

describe '#disconnect [mock only]' do
  it 'returns nil' do
    @redises.mock.disconnect.should be_nil
  end
end
