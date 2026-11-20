require 'rails_helper'

RSpec.describe Whatsapp::MissedCallMessageService do
  let(:account) { create(:account) }
  let(:channel) do
    create(:channel_whatsapp, account: account, provider: 'whatsapp_cloud', validate_provider_config: false, sync_templates: false)
  end
  let(:conversation) { create(:conversation, account: account, inbox: channel.inbox) }
  let(:call) { create(:call, conversation: conversation, provider: :whatsapp, status: 'no_answer') }

  before do
    channel.update!(provider_config: channel.provider_config.merge('missed_call_message_enabled' => true))
    create(:message, conversation: conversation, account: account, inbox: channel.inbox, message_type: :incoming)
  end

  def sent_messages
    conversation.messages.template
  end

  it 'sends the default message once in the call conversation, as an automatic message' do
    described_class.new(call: call).perform
    described_class.new(call: call).perform

    expect(sent_messages.pluck(:content)).to eq([I18n.t('inbox.missed_call_message.default')])
    expect(call.reload.meta['missed_call_message_id']).to eq(sent_messages.last.id)
    expect(sent_messages.last.additional_attributes).to include('missed_call_message' => true)
  end

  it "sends the inbox's own message" do
    channel.update!(provider_config: channel.provider_config.merge('missed_call_message' => 'Reply here'))

    described_class.new(call: call).perform

    expect(sent_messages.pluck(:content)).to eq(['Reply here'])
  end

  it 'does not count as a reply or reopen the conversation' do
    conversation.resolved!

    described_class.new(call: call).perform

    expect(conversation.reload).to have_attributes(status: 'resolved', first_reply_created_at: nil)
  end

  it 'sends nothing while the message is turned off' do
    channel.update!(provider_config: channel.provider_config.merge('missed_call_message_enabled' => false))

    described_class.new(call: call).perform

    expect(sent_messages).to be_empty
  end

  it 'sends nothing for a call an agent answered' do
    call.update!(status: 'completed', accepted_by_agent: create(:user, account: account))

    described_class.new(call: call).perform

    expect(sent_messages).to be_empty
  end

  it "sends nothing once WhatsApp's messaging window has closed" do
    conversation.messages.incoming.update_all(created_at: 25.hours.ago) # rubocop:disable Rails/SkipsModelValidations

    described_class.new(call: call).perform

    expect(sent_messages).to be_empty
  end
end
