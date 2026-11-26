require 'rails_helper'

RSpec.describe Channel::Whatsapp do
  let(:account) { create(:account) }
  let(:channel) do
    create(:channel_whatsapp, account: account, provider: 'whatsapp_cloud', validate_provider_config: false, sync_templates: false)
  end
  let(:invalid_message) { I18n.t('inbox.missed_call_message.invalid', max: Voice::CallAnnouncement::MESSAGE_MAX_LENGTH) }

  def configure(settings)
    channel.provider_config = channel.provider_config.merge(settings)
  end

  it 'is off by default' do
    expect(channel.missed_call_message_enabled?).to be(false)
  end

  it 'accepts a message up to the announcement limit' do
    configure('missed_call_message_enabled' => true, 'missed_call_message' => 'a' * Voice::CallAnnouncement::MESSAGE_MAX_LENGTH)

    channel.missed_call_message_valid

    expect(channel.errors).to be_empty
  end

  {
    'a message over the limit' => { 'missed_call_message' => 'a' * (Voice::CallAnnouncement::MESSAGE_MAX_LENGTH + 1) },
    'a message that is not text' => { 'missed_call_message' => 42 },
    'an on/off value that is not a boolean' => { 'missed_call_message_enabled' => 'true' }
  }.each do |description, settings|
    it "rejects #{description}" do
      configure(settings)

      channel.missed_call_message_valid

      expect(channel.errors.full_messages).to eq([invalid_message])
    end
  end
end
