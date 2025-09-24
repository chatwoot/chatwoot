require 'rails_helper'

RSpec.describe MessageContentPresenter do
  let(:conversation) { create(:conversation) }
  let(:message) { create(:message, conversation: conversation, content_type: content_type, content: content) }
  let(:presenter) { described_class.new(message) }

  describe '#outgoing_content' do
    context 'when message is not input_csat' do
      let(:content_type) { 'text' }
      let(:content) { 'Regular message' }

      it 'returns regular content' do
        expect(presenter.outgoing_content).to eq('Regular message')
      end
    end

    context 'when message is input_csat and inbox is web widget' do
      let(:content_type) { 'input_csat' }
      let(:content) { 'Rate your experience' }

      before do
        allow(message.inbox).to receive(:web_widget?).and_return(true)
      end

      it 'returns regular content without survey URL' do
        expect(presenter.outgoing_content).to eq('Rate your experience')
      end
    end

    context 'when message is input_csat and inbox is not web widget' do
      let(:content_type) { 'input_csat' }
      let(:content) { 'Rate your experience' }

      before do
        allow(message.inbox).to receive(:web_widget?).and_return(false)
      end

      it 'returns I18n default message when no CSAT config and dynamically generates survey URL' do
        with_modified_env 'FRONTEND_URL' => 'https://app.chatwoot.com' do
          expected_url = "https://app.chatwoot.com/survey/responses/#{conversation.uuid}"
          expect(presenter.outgoing_content).to include(expected_url)
        end
      end

      it 'returns CSAT config message when config exists and dynamically generates survey URL' do
        with_modified_env 'FRONTEND_URL' => 'https://app.chatwoot.com' do
          allow(message.inbox).to receive(:csat_config).and_return({ 'message' => 'Custom CSAT message' })
          expected_url = "https://app.chatwoot.com/survey/responses/#{conversation.uuid}"
          expect(presenter.outgoing_content).to eq("Custom CSAT message #{expected_url}")
        end
      end
    end
  end

  describe 'delegation' do
    let(:content_type) { 'text' }
    let(:content) { 'Test message' }

    it 'delegates model methods to the wrapped message' do
      expect(presenter.content).to eq('Test message')
      expect(presenter.content_type).to eq('text')
      expect(presenter.conversation).to eq(conversation)
    end
  end
end
