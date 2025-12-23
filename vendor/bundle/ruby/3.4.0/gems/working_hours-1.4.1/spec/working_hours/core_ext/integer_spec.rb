require 'spec_helper'

describe WorkingHours::CoreExt::Integer do

  describe '#working' do
    it 'returns a DurationProxy' do
      proxy = 42.working
      expect(proxy).to be_kind_of(WorkingHours::DurationProxy)
      expect(proxy.value).to eq(42)
    end
  end

end
