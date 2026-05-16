# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Voice::Provider::Twilio::RecordingAttachmentService do
  let(:account) { create(:account) }
  let(:channel) do
    create(:channel_twilio_sms, :with_voice,
           account: account,
           phone_number: '+15551238888',
           account_sid: 'AC_account_sid',
           auth_token: 'auth_token_value')
  end
  let(:inbox) { channel.inbox }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:call) do
    create(
      :call,
      account: account,
      inbox: inbox,
      conversation: conversation,
      contact: conversation.contact
    )
  end
  let!(:message) do
    msg = conversation.messages.create!(
      account_id: account.id,
      inbox_id: inbox.id,
      message_type: :incoming,
      sender: conversation.contact,
      content: 'Voice Call',
      content_type: 'voice_call'
    )
    call.update!(message_id: msg.id)
    msg
  end

  let(:recording_sid) { 'RE9999' }
  let(:recording_url) { 'https://api.twilio.com/2010-04-01/Accounts/AC1/Recordings/RE9999' }
  let(:recording_duration) { '47' }

  let(:downloaded_tempfile) do
    file = Tempfile.new(['call-recording', '.wav'])
    file.binmode
    file.write('FAKE_AUDIO_BYTES')
    file.rewind
    file
  end

  let(:safe_fetch_result) do
    SafeFetch::Result.new(
      tempfile: downloaded_tempfile,
      filename: 'recording.wav',
      content_type: 'audio/wav'
    )
  end

  before do
    allow(Twilio::VoiceWebhookSetupService).to receive(:new)
      .and_return(instance_double(Twilio::VoiceWebhookSetupService, perform: "AP#{SecureRandom.hex(8)}"))

    allow(SafeFetch).to receive(:fetch)
      .with(recording_url, http_basic_authentication: %w[AC_account_sid auth_token_value],
                           allowed_content_type_prefixes: %w[audio/])
      .and_yield(safe_fetch_result)
  end

  def perform_service(overrides = {})
    described_class.new(
      call: call,
      recording_sid: overrides.fetch(:recording_sid, recording_sid),
      recording_url: overrides.fetch(:recording_url, recording_url),
      recording_duration: overrides.fetch(:recording_duration, recording_duration)
    ).perform
  end

  describe '#perform' do
    it 'attaches the recording to the call and persists recording_sid + duration_seconds' do
      previous_updated_at = message.updated_at
      travel 1.second

      perform_service

      call.reload
      message.reload

      aggregate_failures do
        expect(call.recording).to be_attached
        expect(call.recording_sid).to eq(recording_sid)
        expect(call.duration_seconds).to eq(47)
        expect(message.updated_at).to be > previous_updated_at
      end
    end

    it 'preserves a duration_seconds value that was already set on the call' do
      call.update!(duration_seconds: 99)

      perform_service

      expect(call.reload.duration_seconds).to eq(99)
    end

    it 'is idempotent when the same recording_sid is already attached' do
      perform_service

      expect(SafeFetch).to have_received(:fetch).once

      perform_service

      expect(SafeFetch).to have_received(:fetch).once
      expect(call.reload.recording.blob.checksum).to be_present
    end

    it 'is a no-op when recording_sid is blank' do
      expect { perform_service(recording_sid: '') }.not_to change { call.reload.recording.attached? }.from(false)
      expect(SafeFetch).not_to have_received(:fetch)
    end

    it 'is a no-op when recording_url is blank' do
      expect { perform_service(recording_url: '') }.not_to change { call.reload.recording.attached? }.from(false)
      expect(SafeFetch).not_to have_received(:fetch)
    end
  end
end
