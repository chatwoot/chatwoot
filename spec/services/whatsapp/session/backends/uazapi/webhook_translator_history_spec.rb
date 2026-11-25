require 'rails_helper'

RSpec.describe Whatsapp::Session::Backends::Uazapi::WebhookTranslator do
  let(:channel) { create(:channel_whatsapp, provider: 'uazapi', validate_provider_config: false, sync_templates: false) }

  let(:message) do
    {
      'messageid' => '3EB0AAA', 'chatid' => '5541999990000@s.whatsapp.net', 'sender_pn' => '5541999990000@s.whatsapp.net',
      'fromMe' => false, 'messageType' => 'Conversation', 'text' => 'oi', 'messageTimestamp' => 1_781_824_019_000
    }
  end

  def translate(body)
    described_class.new(channel, body).perform
  end

  it 'turns a history batch into one event carrying every message' do
    events = translate({ 'EventType' => 'history', 'event' => 'messages', 'messages' => [message, message.merge('messageid' => '3EB0BBB')] })

    expect(events.size).to eq(1)
    expect(events.first.payload).to be_a(Whatsapp::Session::Model::Events::HistorySync)
    expect(events.first.payload.data['messages'].map { |m| m['id'] }).to eq(%w[3EB0AAA 3EB0BBB])
  end

  it 'ignores the chats and labels the same event carries' do
    expect(translate({ 'EventType' => 'history', 'event' => 'chats', 'chats' => [{ 'wa_chatid' => 'x' }] })).to be_empty
    expect(translate({ 'EventType' => 'history', 'event' => 'labels', 'labels' => [{ 'id' => 'x' }] })).to be_empty
  end

  it 'drops a history entry with no message id' do
    expect(translate({ 'EventType' => 'history', 'event' => 'messages', 'messages' => [{ 'text' => 'sem id' }] })).to be_empty
  end
end
