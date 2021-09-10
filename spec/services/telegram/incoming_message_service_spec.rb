require 'rails_helper'

describe Telegram::IncomingMessageService do
  let!(:telegram_channel) { create(:channel_telegram) }

  describe '#perform' do
    context 'when valid text message params' do
      it 'creates appropriate conversations, message and contacts' do
        params = {
          'update_id' => 2_342_342_343_242,
          'message' => {
            'message_id' => 1,
            'from' => {
              'id' => 23, 'is_bot' => false, 'first_name' => 'Sojan', 'last_name' => 'Jose', 'username' => 'sojan', 'language_code' => 'en'
            },
            'chat' => { 'id' => 23, 'first_name' => 'Sojan', 'last_name' => 'Jose', 'username' => 'sojan', 'type' => 'private' },
            'date' => 1_631_132_077, 'text' => 'test'
          }
        }.with_indifferent_access
        described_class.new(inbox: telegram_channel.inbox, params: params).perform
        expect(telegram_channel.inbox.conversations).not_to eq(0)
        expect(Contact.all.first.name).to eq('Sojan Jose')
        expect(telegram_channel.inbox.messages.first.content).to eq('test')
      end
    end
  end
end
