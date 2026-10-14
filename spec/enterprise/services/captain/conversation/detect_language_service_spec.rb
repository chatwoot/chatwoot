require 'rails_helper'

RSpec.describe Captain::Conversation::DetectLanguageService do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, additional_attributes: { 'conversation_language' => 'en' }) }

  it 'follows the language of a new incoming message' do
    message = create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :incoming,
                               content: 'Celui-ci met quatre secondes à charger.')

    described_class.new(message: message).perform

    expect(conversation.reload.language).to eq('fr')
  end

  it 'reads an html email from its text nodes' do
    message = create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :incoming,
                               content: '[Voir](https://example.com/_t/c/AAC40W9FOTSX_t_qFpbD) ͏ ͏ ͏ ͏ ͏ ͏ ͏ ͏ ͏ ͏ ͏ ͏ ͏',
                               content_attributes: { email: { html_content: { full: '<p>Celui-ci met quatre secondes à charger.</p>' } } })

    described_class.new(message: message).perform

    expect(conversation.reload.language).to eq('fr')
  end

  it 'ignores messages too short to detect reliably' do
    message = create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :incoming, content: 'ok thanks')

    described_class.new(message: message).perform

    expect(conversation.reload.language).to eq('en')
  end

  it 'follows a contact who switches back to the account language' do
    conversation.update!(additional_attributes: { 'conversation_language' => 'fr' })
    message = create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :incoming,
                               content: 'I want to note three incidents on my account this month.')

    described_class.new(message: message).perform

    expect(conversation.reload.language).to eq('en')
  end

  it 'ignores outgoing messages' do
    message = create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :outgoing,
                               content: 'Celui-ci met quatre secondes à charger.')

    described_class.new(message: message).perform

    expect(conversation.reload.language).to eq('en')
  end

  it 'keeps the stored language when the message is in the same language' do
    message = create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :incoming,
                               content: 'This one takes four seconds to load before it is ready.')

    described_class.new(message: message).perform

    expect(conversation.reload.additional_attributes).to eq('conversation_language' => 'en')
  end
end
