require 'rails_helper'

RSpec.describe Captain::Conversation::MessageLanguageService do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, additional_attributes: { 'conversation_language' => 'en' }) }
  let(:detection) { instance_double(Captain::Llm::LanguageDetectionService, language: 'tr') }

  before do
    allow(Captain::Llm::LanguageDetectionService).to receive(:new).and_return(detection)
  end

  def contact_message(content, language: nil)
    create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :incoming, content: content,
                     source_language: language)
  end

  def detect(message)
    described_class.new(conversation: conversation, message: message).perform
  end

  it 'keeps the conversation language when one short message is detected as another language' do
    4.times { |index| contact_message("Message #{index}", language: 'en') }
    message = contact_message('Istanbul')

    expect(detect(message)).to eq('tr')

    expect(message.reload.source_language).to eq('tr')
    expect(conversation.reload.language).to eq('en')
  end

  it 'follows the contact once most of their recent messages are in the new language' do
    3.times { |index| contact_message("Message #{index}", language: 'en') }
    2.times { |index| contact_message("Mesaj #{index}", language: 'tr') }
    message = contact_message('Merhaba')

    detect(message)

    expect(conversation.reload.language).to eq('tr')
  end
end
