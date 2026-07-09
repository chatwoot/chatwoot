require 'rails_helper'

RSpec.describe Waha::Config do
  describe '.session_ignore' do
    it 'ignores WhatsApp groups by default when creating WAHA sessions' do
      with_modified_env('WAHA_IGNORE_GROUPS' => nil) do
        expect(described_class.session_ignore).to include(groups: true)
      end
    end

    it 'allows the groups ignore flag to be overridden by environment' do
      with_modified_env('WAHA_IGNORE_GROUPS' => 'false') do
        expect(described_class.session_ignore).to include(groups: false)
      end
    end
  end
end
