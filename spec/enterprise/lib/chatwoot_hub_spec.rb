require 'rails_helper'

RSpec.describe ChatwootHub do
  describe '.base_url' do
    it 'ignores CHATWOOT_HUB_URL outside development for enterprise edition' do
      with_modified_env CHATWOOT_HUB_URL: 'https://custom.example.com' do
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('production'))

        expect(described_class.base_url).to eq(Enterprise::ChatwootHub::ENTERPRISE_BASE_URL)
      end
    end

    it 'uses CHATWOOT_HUB_URL in development for enterprise edition' do
      with_modified_env CHATWOOT_HUB_URL: 'https://custom.example.com' do
        allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('development'))

        expect(described_class.base_url).to eq('https://custom.example.com')
      end
    end
  end
end
