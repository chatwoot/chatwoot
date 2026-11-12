require 'rails_helper'

RSpec.describe Voice::CallAnnouncement do
  let(:channel) { create(:channel_twilio_sms) }
  let(:inbox) { channel.inbox }
  let(:message) { 'Please call again tomorrow.' }
  let(:announcement) { described_class.new(inbox, :unanswered) }

  before do
    allow(Llm::TextToSpeechService).to receive(:available_for?).and_return(false)
  end

  describe '#save!' do
    it 'generates audio before saving and retains the upload on the original inbox instance' do
      allow(Llm::TextToSpeechService).to receive(:available_for?).and_return(true)
      generator = instance_double(Llm::TextToSpeechService, perform: 'generated audio')
      allow(Llm::TextToSpeechService).to receive(:new).with(text: message, account: inbox.account).and_return(generator)

      announcement.save!(enabled: true, message: message)

      expect(channel.reload.provider_config).to include('unanswered_call_message' => message)
      expect(inbox.unanswered_call_audio.download).to eq('generated audio')
      expect(inbox.unanswered_call_audio.filename.to_s).to eq("unanswered-#{inbox.id}.mp3")
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
        'recording_enabled' => false, 'inbound_calls_enabled' => false, 'unanswered_call_message' => message
      )
      expect(inbox.reload.unanswered_call_audio.download).to eq('generated audio')
    end

    it 'removes stale audio when the text changes without Captain available' do
      inbox.unanswered_call_audio.attach(io: StringIO.new('old audio'), filename: 'old.mp3', content_type: 'audio/mpeg')

      announcement.save!(enabled: true, message: message)

      expect(channel.reload.provider_config['unanswered_call_message']).to eq(message)
      expect(inbox.reload.unanswered_call_audio).not_to be_attached
    end

    it 'removes audio saved by another request when restoring older text' do
      channel.update!(provider_config: { 'unanswered_call_message' => message })
      inbox.unanswered_call_audio.attach(io: StringIO.new('old audio'), filename: 'old.mp3', content_type: 'audio/mpeg')
      inbox.unanswered_call_audio.blob
      allow(channel).to receive(:with_lock).and_wrap_original do |method, &block|
        other_channel = Channel::TwilioSms.find(channel.id)
        other_channel.inbox.unanswered_call_audio.attach(io: StringIO.new('new audio'), filename: 'new.mp3', content_type: 'audio/mpeg')
        other_channel.update!(provider_config: { 'unanswered_call_message' => 'New announcement.' })
        method.call(&block)
      end

      announcement.save!(enabled: true, message: message)

      expect(channel.reload.provider_config).to include('unanswered_call_message' => message)
      expect(channel.provider_config).not_to have_key('unanswered_calls_enabled')
      expect(inbox.reload.unanswered_call_audio).not_to be_attached
    end

    it 'keeps existing greeting audio without generating again when only the switch changes' do
      greeting = described_class.new(inbox, :greeting)
      channel.update!(provider_config: { 'call_greeting_message' => message })
      inbox.call_greeting_audio.attach(io: StringIO.new('audio'), filename: 'saved.mp3', content_type: 'audio/mpeg')
      old_blob = inbox.call_greeting_audio.blob
      allow(Llm::TextToSpeechService).to receive(:available_for?).and_return(true)
      expect(Llm::TextToSpeechService).not_to receive(:new)

      greeting.save!(enabled: false, message: message)
      greeting.save!(enabled: true, message: message)

      expect(inbox.reload.call_greeting_audio.blob).to eq(old_blob)
    end

    it 'does not record an empty missed-call message' do
      allow(Llm::TextToSpeechService).to receive(:available_for?).and_return(true)
      expect(Llm::TextToSpeechService).not_to receive(:new)

      announcement.save!(enabled: true, message: '')

      expect(announcement.message).to eq(I18n.t('inbox.call_announcements.default_unanswered'))
    end

    it 'saves settings given with the announcement in the same write' do
      described_class.new(inbox, :unanswered)
                     .save!(enabled: true, message: 'Nobody is available.', config: { 'unanswered_call_timeout_seconds' => 45 })

      expect(channel.reload.provider_config).to include(
        'unanswered_call_message' => 'Nobody is available.', 'unanswered_call_timeout_seconds' => 45
      )
    end

    it 'saves a greeting in its own settings when Captain is unavailable' do
      greeting = described_class.new(inbox, :greeting)
      expect(Llm::TextToSpeechService).not_to receive(:new)

      greeting.save!(enabled: true, message: 'Welcome')

      expect(channel.reload.provider_config).to eq('call_greeting_enabled' => true, 'call_greeting_message' => 'Welcome')
      expect(greeting).to be_enabled
      expect(greeting.message).to eq('Welcome')
    end

    it 'keeps the missed-call message always on' do
      expect(announcement).to be_enabled
    end
  end

  describe '#speak' do
    let(:twiml) { Twilio::TwiML::VoiceResponse.new }

    it 'plays the generated audio from an absolute URL Twilio can fetch' do
      inbox.unanswered_call_audio.attach(io: StringIO.new('audio'), filename: 'announcement.mp3', content_type: 'audio/mpeg')

      announcement.speak(twiml)

      play = Nokogiri::XML(twiml.to_s).at_xpath('/Response/Play')
      expect(play.text).to start_with('http://localhost:3000/rails/active_storage/').and end_with('/announcement.mp3')
    end

    it 'has Twilio read the text in the account language when no audio was generated' do
      channel.update!(provider_config: { 'unanswered_call_message' => message })
      inbox.account.update!(locale: 'de')

      announcement.speak(twiml)

      say = Nokogiri::XML(twiml.to_s).at_xpath('/Response/Say')
      expect(say.text).to eq(message)
      expect(say['language']).to eq('de-DE')
    end

    it 'reads the default missed-call message before one is saved' do
      announcement.speak(twiml)

      expect(Nokogiri::XML(twiml.to_s).at_xpath('/Response/Say').text).to eq(I18n.t('inbox.call_announcements.default_unanswered'))
    end

    it 'has Twilio read a greeting' do
      channel.update!(provider_config: { 'call_greeting_message' => 'Welcome' })

      described_class.new(inbox, :greeting).speak(twiml)

      expect(Nokogiri::XML(twiml.to_s).at_xpath('/Response/Say').text).to eq('Welcome')
    end
  end
end
