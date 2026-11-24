require 'rails_helper'

RSpec.describe Voice::Captain::AssistantConfig do
  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account) }

  before { create(:installation_config, name: 'CAPTAIN_VAPI_WEBHOOK_SECRET', value: 'hook-secret') }

  it 'sends tool schemas without the strict flag Vapi rejects' do
    tools = described_class.new(assistant: assistant).to_h.dig(:model, :tools)
    faq_lookup = tools.find { |tool| tool.dig(:function, :name) == 'captain--tools--faq_lookup' }

    expect(faq_lookup.dig(:function, :parameters).keys.map(&:to_s)).to contain_exactly('type', 'properties', 'required', 'additionalProperties')
    expect(tools).to include({ type: 'endCall' })
  end

  it 'sends the webhook secret with every tool and the call report' do
    config = described_class.new(assistant: assistant).to_h

    expect(config.dig(:server, :headers)).to eq(Voice::Captain::WebhookAuth::HEADER => 'hook-secret')
    expect(config.dig(:model, :tools).first.dig(:server, :headers)).to eq(Voice::Captain::WebhookAuth::HEADER => 'hook-secret')
  end
end
