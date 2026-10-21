require 'rails_helper'

RSpec.describe Voice::BusinessHoursSettingsService do
  let(:channel) { create(:channel_twilio_sms) }
  let(:inbox) { channel.inbox }
  let(:message) { 'Please call again tomorrow.' }

  before do
    allow(Llm::TextToSpeechService).to receive(:available_for?).and_return(false)
  end

  it 'generates audio before saving and retains the upload on the original inbox instance' do
    allow(Llm::TextToSpeechService).to receive(:available_for?).and_return(true)
    generator = instance_double(Llm::TextToSpeechService, perform: 'generated audio')
    allow(Llm::TextToSpeechService).to receive(:new).with(text: message, account: inbox.account).and_return(generator)

    described_class.new(inbox: inbox, enabled: true, message: message).perform

    expect(channel.reload.out_of_hours_call_message).to eq(message)
    expect(channel).to be_business_hours_calls_enabled
    expect(inbox.out_of_hours_call_audio.download).to eq('generated audio')
  end

  it 'preserves settings changed by another request during audio generation' do
    allow(Llm::TextToSpeechService).to receive(:available_for?).and_return(true)
    generator = instance_double(Llm::TextToSpeechService)
    allow(Llm::TextToSpeechService).to receive(:new).with(text: message, account: inbox.account).and_return(generator)
    allow(generator).to receive(:perform) do
      other_channel = Channel::TwilioSms.find(channel.id)
      other_channel.update!(provider_config: other_channel.provider_config.merge(
        'recording_enabled' => false, 'inbound_calls_enabled' => false
      ))
      'generated audio'
    end

    described_class.new(inbox: inbox, enabled: true, message: message).perform

    expect(channel.reload.provider_config).to include(
      'recording_enabled' => false, 'inbound_calls_enabled' => false,
      'business_hours_calls_enabled' => true, 'out_of_hours_call_message' => message
    )
    expect(inbox.reload.out_of_hours_call_audio.download).to eq('generated audio')
  end

  it 'removes stale audio when the text changes without Captain available' do
    inbox.out_of_hours_call_audio.attach(io: StringIO.new('old audio'), filename: 'old.mp3', content_type: 'audio/mpeg')

    described_class.new(inbox: inbox, enabled: true, message: message).perform

    expect(channel.reload.out_of_hours_call_message).to eq(message)
    expect(inbox.reload.out_of_hours_call_audio).not_to be_attached
  end

  it 'removes audio saved by another request when restoring older text while disabling calls' do
    channel.update!(provider_config: { 'out_of_hours_call_message' => message })
    inbox.out_of_hours_call_audio.attach(io: StringIO.new('old audio'), filename: 'old.mp3', content_type: 'audio/mpeg')
    inbox.out_of_hours_call_audio.blob
    allow(channel).to receive(:with_lock).and_wrap_original do |method, &block|
      other_channel = Channel::TwilioSms.find(channel.id)
      other_channel.inbox.out_of_hours_call_audio.attach(io: StringIO.new('new audio'), filename: 'new.mp3', content_type: 'audio/mpeg')
      other_channel.update!(provider_config: { 'out_of_hours_call_message' => 'New announcement.' })
      method.call(&block)
    end

    described_class.new(inbox: inbox, enabled: false, message: message).perform

    expect(channel.reload.out_of_hours_call_message).to eq(message)
    expect(channel).not_to be_business_hours_calls_enabled
    expect(inbox.reload.out_of_hours_call_audio).not_to be_attached
  end

  it 'keeps existing audio without generating again when only the toggle changes' do
    channel.update!(provider_config: { 'out_of_hours_call_message' => message })
    inbox.out_of_hours_call_audio.attach(io: StringIO.new('audio'), filename: 'saved.mp3', content_type: 'audio/mpeg')
    old_blob = inbox.out_of_hours_call_audio.blob
    allow(Llm::TextToSpeechService).to receive(:available_for?).and_return(true)
    expect(Llm::TextToSpeechService).not_to receive(:new)

    described_class.new(inbox: inbox, enabled: false, message: message).perform
    described_class.new(inbox: inbox, enabled: true, message: message).perform

    expect(inbox.reload.out_of_hours_call_audio.blob).to eq(old_blob)
  end
end
