require 'rails_helper'

RSpec.describe Integrations::LlmBaseService do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:hook) { create(:integrations_hook, :openai, account: account, settings: { 'api_key' => 'hook-key' }) }
  let(:event) { { 'name' => 'summarize', 'data' => { 'conversation_display_id' => conversation.display_id } } }
  let(:service) { described_class.new(hook: hook, event: event) }
  let(:error) { StandardError.new('API Error') }
  let(:body) { { model: 'gpt-4', messages: [{ role: 'user', content: 'Hello' }] }.to_json }

  describe '#make_api_call' do
    before do
      allow(service).to receive(:instrument_llm_call).and_yield
      allow(Llm::Config).to receive(:with_api_key).and_raise(error)
    end

    it 'does not track exceptions for hook key failures' do
      expect(ChatwootExceptionTracker).not_to receive(:new)

      result = service.send(:make_api_call, body)

      expect(result[:error]).to eq('API Error')
      expect(result[:request_messages]).to eq([{ 'role' => 'user', 'content' => 'Hello' }])
    end
  end
end
