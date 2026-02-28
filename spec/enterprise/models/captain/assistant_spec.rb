require 'rails_helper'

RSpec.describe Captain::Assistant, type: :model do
  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account) }

  describe '#available_agent_tools' do
    before do
      allow(described_class).to receive(:built_in_agent_tools).and_return([
                                                                            { id: 'faq_lookup', title: 'FAQ' },
                                                                            { id: 'shopify_search_products', title: 'Products' },
                                                                            { id: 'shopify_get_orders', title: 'Orders' }
                                                                          ])
    end

    it 'hides shopify tools when account is not eligible for v2 shopify' do
      allow(account).to receive(:feature_enabled?).with('captain_integration_v2').and_return(false)

      expect(assistant.available_agent_tools.pluck(:id)).to eq(['faq_lookup'])
    end

    it 'shows shopify tools when v2 is enabled and shopify is connected' do
      create(:integrations_hook, :shopify, account: account)
      allow(account).to receive(:feature_enabled?).with('captain_integration_v2').and_return(true)

      expect(assistant.available_agent_tools.pluck(:id)).to contain_exactly('faq_lookup', 'shopify_search_products', 'shopify_get_orders')
    end
  end

  describe '#agent_tools' do
    let(:faq_tool_class) do
      Class.new do
        def initialize(_assistant); end
      end
    end

    let(:handoff_tool_class) do
      Class.new do
        def initialize(_assistant); end
      end
    end

    let(:search_tool_class) do
      Class.new do
        def initialize(_assistant); end
      end
    end

    let(:orders_tool_class) do
      Class.new do
        def initialize(_assistant); end
      end
    end

    before do
      allow(described_class).to receive(:resolve_tool_class).with('faq_lookup').and_return(faq_tool_class)
      allow(described_class).to receive(:resolve_tool_class).with('handoff').and_return(handoff_tool_class)
      allow(described_class).to receive(:resolve_tool_class).with('shopify_search_products').and_return(search_tool_class)
      allow(described_class).to receive(:resolve_tool_class).with('shopify_get_orders').and_return(orders_tool_class)
    end

    it 'includes only default tools when account is ineligible' do
      allow(account).to receive(:feature_enabled?).with('captain_integration_v2').and_return(false)

      expect(assistant.send(:agent_tools).length).to eq(2)
    end

    it 'includes shopify tools when account is eligible' do
      create(:integrations_hook, :shopify, account: account)
      allow(account).to receive(:feature_enabled?).with('captain_integration_v2').and_return(true)

      expect(assistant.send(:agent_tools).length).to eq(4)
    end
  end
end
