require 'rails_helper'

RSpec.describe Captain::Conversation::MessageLanguageService do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, additional_attributes: { 'conversation_language' => 'en' }) }
  let(:languages) do
    { 'Istanbul' => 'tr', 'Tammam' => 'hi', 'Merhaba' => 'tr', 'Tamam' => 'tr', 'Merci' => 'fr',
      'Perdón, prefiero hablar en español' => 'es', 'Hola, necesito ayuda con mi pedido' => 'es',
      "Je suis absent jusqu'au lundi" => 'fr', '注文がまだ届いていません' => 'ja',
      'ទំនិញមិនទាន់មកដល់ទេ' => 'km', 'Tamam 👍 34000 !' => 'tr' }
  end

  before do
    allow(Captain::Llm::LanguageDetectionService).to receive(:new) do |text:, **|
      instance_double(Captain::Llm::LanguageDetectionService, language: languages.fetch(text, 'en'), failed?: false)
    end
  end

  def contact_message(content, language: nil, **attributes)
    create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :incoming, content: content,
                     source_language: language, **attributes)
  end

  def detect(message)
    described_class.new(conversation: conversation.reload, message: message).perform
  end

  it 'keeps the conversation language when one short message is detected as another language' do
    4.times { |index| contact_message("Message number #{index}", language: 'en') }
    message = contact_message('Istanbul')

    expect(detect(message)).to eq('tr')

    expect(message.reload.source_language).to eq('tr')
    expect(conversation.reload.language).to eq('en')
  end

  it 'keeps the conversation language when the second message is one word in another language' do
    contact_message('Hi, I need the payment receipt for my order', language: 'en')

    detect(contact_message('Tammam'))

    expect(conversation.reload.language).to eq('en')
  end

  it 'switches straight away on a full sentence in another language' do
    3.times { |index| contact_message("Message number #{index}", language: 'en') }

    detect(contact_message('Perdón, prefiero hablar en español'))

    expect(conversation.reload.language).to eq('es')
  end

  it 'switches straight away on a sentence in a script written without spaces' do
    contact_message('Hi, I need help with my order', language: 'en')

    detect(contact_message('注文がまだ届いていません'))
    expect(conversation.reload.language).to eq('ja')

    detect(contact_message('ទំនិញមិនទាន់មកដល់ទេ'))
    expect(conversation.reload.language).to eq('km')
  end

  it 'does not count numbers, emoji or punctuation as words' do
    contact_message('Hi, I need help with my order', language: 'en')

    detect(contact_message('Tamam 👍 34000 !'))

    expect(conversation.reload.language).to eq('en')
  end

  it 'switches on a short message once it agrees with the message before it' do
    contact_message('Hi, I need help with my order', language: 'en')

    detect(contact_message('Merhaba'))
    expect(conversation.reload.language).to eq('en')

    detect(contact_message('Tamam'))
    expect(conversation.reload.language).to eq('tr')
  end

  it 'corrects the language when older messages are detected after the newest one' do
    conversation.update!(additional_attributes: {})
    older = Array.new(4) { |index| contact_message("ok #{index}") }
    detect(contact_message('Istanbul'))
    expect(conversation.reload.language).to eq('tr')

    older.reverse_each { |message| detect(message) }

    expect(conversation.reload.language).to eq('en')
  end

  context 'with an email inbox' do
    let(:inbox) { create(:channel_email, account: account).inbox }

    it 'leaves email auto replies out' do
      contact_message('Hello, I have a question', language: 'en', content_type: :incoming_email)
      auto_reply = contact_message("Je suis absent jusqu'au lundi", content_type: :incoming_email,
                                                                    content_attributes: { email: { auto_reply: true } })
      detect(auto_reply)
      expect(conversation.reload.language).to eq('en')

      detect(contact_message('Merci', content_type: :incoming_email))

      expect(conversation.reload.language).to eq('en')
    end
  end
end
