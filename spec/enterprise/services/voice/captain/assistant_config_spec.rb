require 'rails_helper'

RSpec.describe Voice::Captain::AssistantConfig do
  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account) }
  let(:voice) { 'Elliot' }
  let(:time_zone) { 'UTC' }
  let(:config) do
    described_class.new(assistant: assistant, voice: voice, caller_number: '+14155550123', time_zone: time_zone).to_h
  end
  let(:tools) { config.dig(:model, :tools) }
  let(:system_prompt) { config.dig(:model, :messages, 0, :content) }

  before { create(:installation_config, name: 'CAPTAIN_VAPI_WEBHOOK_SECRET', value: 'hook-secret') }

  it 'sends tool schemas without the strict flag Vapi rejects' do
    faq_lookup = tools.find { |tool| tool.dig(:function, :name) == 'captain--tools--faq_lookup' }

    expect(faq_lookup.dig(:function, :parameters).keys.map(&:to_s)).to contain_exactly('type', 'properties', 'required', 'additionalProperties')
    expect(tools).to include({ type: 'endCall' })
  end

  it 'varies what Captain says while it looks something up' do
    faq_lookup = tools.find { |tool| tool.dig(:function, :name) == 'captain--tools--faq_lookup' }

    expect(faq_lookup[:messages]).to eq(described_class::LOOKUP_PHRASES.map { |phrase| { type: 'request-start', content: phrase } })
  end

  it 'tells the caller they are being connected when Captain hands off' do
    handoff = tools.find { |tool| tool.dig(:function, :name) == 'captain--tools--handoff' }

    expect(handoff[:messages]).to eq([{ type: 'request-start', content: described_class::HANDOFF_PHRASE }])
  end

  describe 'call details in the prompt' do
    let(:time_zone) { 'Asia/Kolkata' }

    it 'gives the current time in the inbox time zone' do
      travel_to Time.utc(2026, 11, 26, 20, 0) do
        expect(system_prompt).to include('The current time is Friday, November 27, 2026 01:30 AM IST (Asia/Kolkata)')
      end
    end

    it "gives the caller's number for tools that need it" do
      expect(system_prompt).to include('The caller is calling from +14155550123')
    end
  end

  it 'turns off background speech denoising' do
    expect(config[:backgroundSpeechDenoisingPlan]).to eq(smartDenoisingPlan: { enabled: false }, fourierDenoisingPlan: { enabled: false })
  end

  context 'with another voice chosen' do
    let(:voice) { 'Naina' }

    it 'speaks with that Vapi voice' do
      expect(config[:voice]).to eq(provider: 'vapi', voiceId: 'Naina', version: 2)
    end
  end

  it 'turns off the background office sound' do
    expect(config[:backgroundSound]).to eq('off')
  end

  it 'sends the webhook secret with every tool and the call report' do
    expect(config.dig(:server, :headers)).to eq(Voice::Captain::WebhookAuth::HEADER => 'hook-secret')
    expect(tools.first.dig(:server, :headers)).to eq(Voice::Captain::WebhookAuth::HEADER => 'hook-secret')
  end
end
