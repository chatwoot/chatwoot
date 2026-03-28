# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Voice::Provider::Twilio::RecordingAttachmentService do
  let(:account) { create(:account) }
  let(:channel) { create(:channel_voice, account: account, phone_number: '+15551230009') }
  let(:inbox) { channel.inbox }
  let(:contact) { create(:contact, account: account, phone_number: '+15550009999') }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: inbox, source_id: contact.phone_number) }
  let(:conversation) do
    create(
      :conversation,
      account: account,
      inbox: inbox,
      contact: contact,
      contact_inbox: contact_inbox
    )
  end
  let(:voice_call_message) do
    create(
      :message,
      account: account,
      conversation: conversation,
      inbox: inbox,
      sender: contact,
      message_type: :incoming,
      content: 'Voice Call',
      content_type: 'voice_call',
      content_attributes: {
        'data' => {
          'status' => 'completed',
          'meta' => {
            'duration' => 42
          }
        }
      }
    )
  end
  let(:recording_sid) { 'RE-recording-123' }
  let(:recording_url) { 'https://api.twilio.com/2010-04-01/Accounts/AC123/Recordings/RE-recording-123' }
  let(:recording_file) do
    Tempfile.new(['call-recording', '.wav']).tap do |file|
      file.write('fake wav content')
      file.rewind
      file.define_singleton_method(:content_type) { 'audio/wav' }
      file.define_singleton_method(:original_filename) { 'call-recording.wav' }
      file.define_singleton_method(:close!) do
        close
        unlink
      end
    end
  end

  before do
    allow(Twilio::VoiceWebhookSetupService).to receive(:new)
      .and_return(instance_double(Twilio::VoiceWebhookSetupService, perform: "AP#{SecureRandom.hex(16)}"))
    channel
    voice_call_message
    allow(Down).to receive(:download).with(
      recording_url,
      http_basic_authentication: [
        channel.provider_config_hash['account_sid'],
        channel.provider_config_hash['auth_token']
      ]
    ).and_return(recording_file)
    allow(Messages::AudioTranscriptionJob).to receive(:perform_later)
  end

  it 'attaches the recording to the existing voice_call message' do
    described_class.new(
      conversation: conversation,
      recording_sid: recording_sid,
      recording_url: recording_url,
      recording_duration: '42'
    ).perform

    voice_call_message.reload

    expect(voice_call_message.attachments.size).to eq(1)
    expect(voice_call_message.attachments.first.file_type).to eq('audio')
    expect(voice_call_message.content_attributes.dig('data', 'meta', 'recording')).to eq(
      { 'sid' => recording_sid, 'duration' => 42 }
    )
  end

  it 'is idempotent for the same recording sid' do
    service = described_class.new(
      conversation: conversation,
      recording_sid: recording_sid,
      recording_url: recording_url
    )

    service.perform
    service.perform

    voice_call_message.reload

    expect(voice_call_message.attachments.count).to eq(1)
    expect(voice_call_message.content_attributes.dig('data', 'meta', 'recording', 'sid')).to eq(recording_sid)
  end
end
