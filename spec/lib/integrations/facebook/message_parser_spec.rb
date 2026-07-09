# frozen_string_literal: true

require 'rails_helper'

describe Integrations::Facebook::MessageParser do
  describe '#sent_from_chatwoot_app?' do
    before do
      create(:installation_config, name: 'FB_APP_ID', value: '1134227931892276')
    end

    it 'returns true when the echo app_id matches FB_APP_ID' do
      response = described_class.new({ messaging: { message: { is_echo: true, app_id: '1134227931892276' } } }.to_json)
      expect(response.sent_from_chatwoot_app?).to be true
    end

    it 'returns false when the echo app_id does not match FB_APP_ID' do
      response = described_class.new({ messaging: { message: { is_echo: true, app_id: '999999999999999' } } }.to_json)
      expect(response.sent_from_chatwoot_app?).to be false
    end

    it 'returns false when app_id is absent from the payload' do
      response = described_class.new({ messaging: { message: { is_echo: true } } }.to_json)
      expect(response.sent_from_chatwoot_app?).to be false
    end
  end

  describe '#echo?' do
    it 'returns true when message.is_echo is true' do
      response = described_class.new({ messaging: { message: { is_echo: true } } }.to_json)
      expect(response.echo?).to be true
    end

    it 'returns falsey when message.is_echo is absent' do
      response = described_class.new({ messaging: { message: {} } }.to_json)
      expect(response.echo?).to be_falsey
    end
  end
end
