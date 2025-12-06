require 'rails_helper'

RSpec.describe 'Multi-channel audio transcription', type: :integration do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account: account) }

  before do
    # Create OpenAI integration hook with audio_transcription enabled
    create(:integrations_hook, account: account, app_id: 'openai', status: 'enabled',
                               settings: { 'api_key' => 'test-api-key', 'audio_transcription' => true })

    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('AUDIO_TRANSCRIPTION_ENABLED', 'true').and_return('true')
    allow(ENV).to receive(:fetch).with('OPENAI_API_KEY', nil).and_return('test-api-key')

    # Stub WhatsApp API calls
    stub_request(:post, 'https://waba.360dialog.io/v1/configs/webhook')
      .to_return(status: 200, body: '', headers: {})
    stub_request(:get, 'https://waba.360dialog.io/v1/configs/templates')
      .to_return(status: 200, body: { waba_templates: [] }.to_json, headers: {})
  end

  shared_examples 'triggers audio transcription' do
    it 'enqueues transcription job when message with audio is created' do
      message = create(:message, message_type: 'incoming', account: account, inbox: inbox, conversation: conversation)
      attachment = message.attachments.build(account_id: account.id, file_type: :audio)
      attachment.file.attach(
        io: File.open(Rails.root.join('spec/assets/sample.mp3')),
        filename: 'sample.mp3',
        content_type: 'audio/mpeg'
      )
      attachment.save!
      message.reload

      # Manually dispatch the event after attachment is created
      perform_enqueued_jobs(only: EventDispatcherJob) do
        Rails.configuration.dispatcher.dispatch('message.created', Time.zone.now, message: message)
      end

      expect(TranscribeAudioMessageJob).to have_been_enqueued.with(message.id, attachment.id)
    end
  end

  context 'when message is created via API inbox' do
    let!(:api_channel) { create(:channel_api, account: account) }
    let!(:inbox) { create(:inbox, channel: api_channel, account: account) }
    let!(:conversation) { create(:conversation, account: account, inbox: inbox) }

    it_behaves_like 'triggers audio transcription'
  end

  context 'when message is created via Widget inbox' do
    let!(:widget_channel) { create(:channel_widget, account: account) }
    let!(:inbox) { create(:inbox, channel: widget_channel, account: account) }
    let!(:conversation) { create(:conversation, account: account, inbox: inbox) }

    it_behaves_like 'triggers audio transcription'
  end

  context 'when message is created via WhatsApp inbox' do
    let!(:whatsapp_channel) { create(:channel_whatsapp, account: account) }
    let!(:inbox) { create(:inbox, channel: whatsapp_channel, account: account) }
    let!(:conversation) { create(:conversation, account: account, inbox: inbox) }

    it_behaves_like 'triggers audio transcription'
  end

  context 'when message is created via Email inbox' do
    let!(:email_channel) { create(:channel_email, account: account) }
    let!(:inbox) { create(:inbox, channel: email_channel, account: account) }
    let!(:conversation) { create(:conversation, account: account, inbox: inbox) }

    it_behaves_like 'triggers audio transcription'
  end

  context 'when transcription is disabled globally' do
    let!(:inbox) { create(:inbox, account: account) }
    let!(:conversation) { create(:conversation, account: account, inbox: inbox) }

    before do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with('AUDIO_TRANSCRIPTION_ENABLED', 'true').and_return('false')
    end

    it 'does not enqueue transcription job' do
      expect(TranscribeAudioMessageJob).not_to receive(:perform_later)
      message = create(:message, message_type: 'incoming', account: account, inbox: inbox, conversation: conversation)
      attachment = message.attachments.build(account_id: account.id, file_type: :audio)
      attachment.file.attach(
        io: File.open(Rails.root.join('spec/assets/sample.mp3')),
        filename: 'sample.mp3',
        content_type: 'audio/mpeg'
      )
      attachment.save!
    end
  end

  context 'when message has no attachments' do
    let!(:inbox) { create(:inbox, account: account) }
    let!(:conversation) { create(:conversation, account: account, inbox: inbox) }

    it 'does not enqueue transcription job' do
      expect(TranscribeAudioMessageJob).not_to receive(:perform_later)
      create(:message, message_type: 'incoming', account: account, inbox: inbox, conversation: conversation, content: 'Hello')
    end
  end

  context 'when message has only image attachments' do
    let!(:inbox) { create(:inbox, account: account) }
    let!(:conversation) { create(:conversation, account: account, inbox: inbox) }

    it 'does not enqueue transcription job' do
      expect(TranscribeAudioMessageJob).not_to receive(:perform_later)
      message = create(:message, message_type: 'incoming', account: account, inbox: inbox, conversation: conversation)
      attachment = message.attachments.build(account_id: account.id, file_type: :image)
      attachment.file.attach(
        io: File.open(Rails.root.join('spec/assets/avatar.png')),
        filename: 'avatar.png',
        content_type: 'image/png'
      )
      attachment.save!
    end
  end
end
