require 'rails_helper'

RSpec.describe ConversationMonitors::AttachmentTracking do
  let(:account) { create(:account) }
  let(:monitor) { create(:conversation_monitor, account: account, created_at: 1.day.ago) }
  let(:conversation) { create(:conversation, account: account) }
  let(:message) { create(:message, account: account, conversation: conversation, content: nil) }
  let(:attachment) { message.attachments.create!(account: account, file_type: :audio, external_url: 'https://example.test/audio') }
  let(:work) { ConversationMonitors::WorkItem.find_by!(conversation: conversation) }
  let(:endpoint) { ConversationMonitors::Configuration.endpoint }

  before do
    account.enable_features!('reports', 'conversation_monitors')
    create(:installation_config, name: 'CAPTAIN_OPENROUTER_API_KEY', value: 'test-key')
    monitor
    allow(message).to receive(:send_update_event)
    attachment
    stub_request(:post, endpoint).to_return(status: 200, body: {
      model: 'typesafe/jev-1.13', answers: { monitor.id.to_s => { type: 'noul', noul: 0.9 } }, usage: { input_tokens: 10 }
    }.to_json)
  end

  %i[incoming outgoing].each do |type|
    it "evaluates a completed #{type} transcript after an earlier no-text result" do
      message.update!(message_type: type)
      work.update!(due_at: Time.current)
      ConversationMonitors::Evaluator.new(work).perform
      expect(monitor.evaluations.sole.error_code).to eq('no_text')
      service = Messages::AudioTranscriptionService.new(attachment)
      allow(service.message).to receive(:send_update_event)
      allow(ChatwootApp).to receive(:advanced_search_allowed?).and_return(false)

      expect { service.send(:update_transcription, 'I need a refund') }
        .to have_enqueued_job(ConversationMonitors::ProcessJob).with(conversation.id)
      expect(work.reload.full_history_revision).to be > work.processed_revision
      work.update!(due_at: Time.current)
      ConversationMonitors::Evaluator.new(work).perform

      expect(monitor.evaluations.sole.status).to eq('matched')
      expect(WebMock).to have_requested(:post, endpoint).with { |request| request.body.include?('I need a refund') }.once
    end
  end

  it 'preserves a previous match when more transcript evidence arrives' do
    monitor.evaluations.create!(account: account, conversation: conversation, status: 'matched')
    attachment.update!(meta: { transcribed_text: 'I need a refund' })
    work.reload.update!(due_at: Time.current)
    ConversationMonitors::Evaluator.new(work).perform

    expect(monitor.evaluations.sole.status).to eq('matched')
    expect(WebMock).not_to have_requested(:post, endpoint)
  end

  [{ private: true }, { content: 'Existing text' }, { content_attributes: { deleted: true } }, { message_type: :activity }].each do |attributes|
    it "ignores transcripts not used as public evidence: #{attributes}" do
      message.update!(attributes)

      expect { attachment.update!(meta: { transcribed_text: 'I need a refund' }) }.not_to(change { work.reload.revision })
    end
  end

  it 'ignores unchanged transcripts and unrelated metadata' do
    attachment.update!(meta: { transcribed_text: 'I need a refund' })

    expect { attachment.update!(meta: attachment.meta.merge('duration' => 5)) }.not_to(change { work.reload.revision })
  end
end
