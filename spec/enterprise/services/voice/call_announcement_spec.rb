require 'rails_helper'

RSpec.describe Voice::CallAnnouncement do
  let(:channel) { create(:channel_twilio_sms) }
  let(:inbox) { channel.inbox }
  let(:message) { 'Please call again tomorrow.' }
  let(:announcement) { described_class.new(inbox, :out_of_hours) }

  before do
    allow(Llm::TextToSpeechService).to receive(:available_for?).and_return(false)
  end

  describe '#save!' do
    it 'generates audio before saving and retains the upload on the original inbox instance' do
      allow(Llm::TextToSpeechService).to receive(:available_for?).and_return(true)
      generator = instance_double(Llm::TextToSpeechService, perform: 'generated audio')
      allow(Llm::TextToSpeechService).to receive(:new).with(text: message, account: inbox.account).and_return(generator)

      announcement.save!(enabled: true, message: message)

      expect(channel.reload.provider_config).to include('business_hours_calls_enabled' => true, 'out_of_hours_call_message' => message)
      expect(inbox.out_of_hours_call_audio.download).to eq('generated audio')
      expect(inbox.out_of_hours_call_audio.filename.to_s).to eq("out-of-hours-#{inbox.id}.mp3")
    end

    it 'preserves settings changed by another request during audio generation' do
      allow(Llm::TextToSpeechService).to receive(:available_for?).and_return(true)
      generator = instance_double(Llm::TextToSpeechService)
      allow(Llm::TextToSpeechService).to receive(:new).with(text: message, account: inbox.account).and_return(generator)
      allow(generator).to receive(:perform) do
        other_channel = Channel::TwilioSms.find(channel.id)
        other_channel.update!(provider_config: other_channel.provider_config.merge('recording_enabled' => false, 'inbound_calls_enabled' => false))
        'generated audio'
      end

      announcement.save!(enabled: true, message: message)

      expect(channel.reload.provider_config).to include(
        'recording_enabled' => false, 'inbound_calls_enabled' => false,
        'business_hours_calls_enabled' => true, 'out_of_hours_call_message' => message
      )
      expect(inbox.reload.out_of_hours_call_audio.download).to eq('generated audio')
    end

    it 'removes stale audio when the text changes without Captain available' do
      inbox.out_of_hours_call_audio.attach(io: StringIO.new('old audio'), filename: 'old.mp3', content_type: 'audio/mpeg')

      announcement.save!(enabled: true, message: message)

      expect(channel.reload.provider_config['out_of_hours_call_message']).to eq(message)
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

      announcement.save!(enabled: false, message: message)

      expect(channel.reload.provider_config).to include('business_hours_calls_enabled' => false, 'out_of_hours_call_message' => message)
      expect(inbox.reload.out_of_hours_call_audio).not_to be_attached
    end

    it 'keeps existing audio without generating again when only the toggle changes' do
      channel.update!(provider_config: { 'out_of_hours_call_message' => message })
      inbox.out_of_hours_call_audio.attach(io: StringIO.new('audio'), filename: 'saved.mp3', content_type: 'audio/mpeg')
      old_blob = inbox.out_of_hours_call_audio.blob
      allow(Llm::TextToSpeechService).to receive(:available_for?).and_return(true)
      expect(Llm::TextToSpeechService).not_to receive(:new)

      announcement.save!(enabled: false, message: message)
      announcement.save!(enabled: true, message: message)

      expect(inbox.reload.out_of_hours_call_audio.blob).to eq(old_blob)
    end

    it 'saves a greeting as text only, in its own settings' do
      greeting = described_class.new(inbox, :greeting)
      allow(Llm::TextToSpeechService).to receive(:available_for?).and_return(true)
      expect(Llm::TextToSpeechService).not_to receive(:new)

      greeting.save!(enabled: true, message: 'Welcome')

      expect(channel.reload.provider_config).to eq('call_greeting_enabled' => true, 'call_greeting_message' => 'Welcome')
      expect(greeting).to be_enabled
      expect(greeting.message).to eq('Welcome')
      expect(announcement).not_to be_enabled
    end
  end

  describe '#speak' do
    let(:twiml) { Twilio::TwiML::VoiceResponse.new }

    it 'plays the generated audio from an absolute URL Twilio can fetch' do
      inbox.out_of_hours_call_audio.attach(io: StringIO.new('audio'), filename: 'announcement.mp3', content_type: 'audio/mpeg')

      announcement.speak(twiml)

      play = Nokogiri::XML(twiml.to_s).at_xpath('/Response/Play')
      expect(play.text).to start_with('http://localhost:3000/rails/active_storage/').and end_with('/announcement.mp3')
    end

    it 'has Twilio read the text in the account language when no audio was generated' do
      channel.update!(provider_config: { 'out_of_hours_call_message' => message })
      inbox.account.update!(locale: 'de')

      announcement.speak(twiml)

      say = Nokogiri::XML(twiml.to_s).at_xpath('/Response/Say')
      expect(say.text).to eq(message)
      expect(say['language']).to eq('de-DE')
    end

    it 'has Twilio read a greeting' do
      channel.update!(provider_config: { 'call_greeting_message' => 'Welcome' })

      described_class.new(inbox, :greeting).speak(twiml)

      expect(Nokogiri::XML(twiml.to_s).at_xpath('/Response/Say').text).to eq('Welcome')
    end
  end
end
