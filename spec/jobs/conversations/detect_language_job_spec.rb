require 'rails_helper'
require 'google/cloud/translate/v3'

RSpec.describe Conversations::DetectLanguageJob, type: :job do
  include ActiveJob::TestHelper

  subject(:job) { described_class.perform_later(message.id) }

  let(:account) { create(:account) }
  let(:message) { create(:message, account: account, content: 'muchas muchas gracias') }
  let(:client) { double }

  context 'when message created' do
    it 'calls Integrations::Slack::SendOnSlackService when its a slack hook' do
      perform_enqueued_jobs do
        create(:integrations_hook, :google_translate, account_id: account.id)
        response = Google::Cloud::Translate::V3::DetectLanguageResponse.new({ languages: [{ language_code: 'es', confidence: 0.71875 }] })

        allow(Google::Cloud::Translate).to receive(:translation_service).and_return(client)
        allow(client).to receive(:detect_language).and_return(response)
      end

      described_class.perform_now(message.id)
      expect(message.conversation.reload.additional_attributes['conversation_language']).to eq('es')
    end
  end
end
