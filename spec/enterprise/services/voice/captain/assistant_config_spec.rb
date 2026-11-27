require 'rails_helper'

RSpec.describe Voice::Captain::AssistantConfig do
  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account) }

  before { create(:installation_config, name: 'CAPTAIN_VAPI_WEBHOOK_SECRET', value: 'hook-secret') }

  it 'sends tool schemas without the strict flag Vapi rejects' do
    tools = described_class.new(assistant: assistant, voice: 'Elliot').to_h.dig(:model, :tools)
    faq_lookup = tools.find { |tool| tool.dig(:function, :name) == 'captain--tools--faq_lookup' }

    expect(faq_lookup.dig(:function, :parameters).keys.map(&:to_s)).to contain_exactly('type', 'properties', 'required', 'additionalProperties')
    expect(tools).to include({ type: 'endCall' })
  end

  it 'varies what Captain says while it looks something up' do
    tools = described_class.new(assistant: assistant, voice: 'Elliot').to_h.dig(:model, :tools)
    faq_lookup = tools.find { |tool| tool.dig(:function, :name) == 'captain--tools--faq_lookup' }

    expect(faq_lookup[:messages]).to eq(described_class::LOOKUP_PHRASES.map { |phrase| { type: 'request-start', content: phrase } })
  end

  it 'tells the caller they are being connected when Captain hands off' do
    tools = described_class.new(assistant: assistant, voice: 'Elliot').to_h.dig(:model, :tools)
    handoff = tools.find { |tool| tool.dig(:function, :name) == 'captain--tools--handoff' }

    expect(handoff[:messages]).to eq([{ type: 'request-start', content: described_class::HANDOFF_PHRASE }])
  end

  it 'turns off background speech denoising' do
    plan = described_class.new(assistant: assistant, voice: 'Elliot').to_h[:backgroundSpeechDenoisingPlan]

    expect(plan).to eq(smartDenoisingPlan: { enabled: false }, fourierDenoisingPlan: { enabled: false })
  end

  it 'speaks with the chosen Vapi voice' do
    config = described_class.new(assistant: assistant, voice: 'Naina').to_h

    expect(config[:voice]).to eq(provider: 'vapi', voiceId: 'Naina', version: 2)
  end

  it 'turns off the background office sound' do
    expect(described_class.new(assistant: assistant, voice: 'Elliot').to_h[:backgroundSound]).to eq('off')
  end

  it 'sends the webhook secret with every tool and the call report' do
    config = described_class.new(assistant: assistant, voice: 'Elliot').to_h

    expect(config.dig(:server, :headers)).to eq(Voice::Captain::WebhookAuth::HEADER => 'hook-secret')
    expect(config.dig(:model, :tools).first.dig(:server, :headers)).to eq(Voice::Captain::WebhookAuth::HEADER => 'hook-secret')
  end
end
