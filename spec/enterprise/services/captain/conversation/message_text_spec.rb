require 'rails_helper'

RSpec.describe Captain::Conversation::MessageText do
  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account) }
  let(:html) do
    '<style>p { color: red }</style><div><p>Bonjour <b>Camille</b></p><p>Merci</p></div>' \
      '<blockquote class="gmail_quote"><p>Ancien message</p></blockquote>'
  end
  let(:email) do
    create(:message, account: account, conversation: conversation, message_type: :incoming, content: 'Bonjour Camille',
                     content_attributes: { email: { html_content: { full: html } } })
  end

  it 'reads the text nodes of an html email, without styles or the quoted history' do
    expect(described_class.new(email).texts).to eq(%w[Bonjour Camille Merci])
  end

  it 'puts the translations back into the markup' do
    expect(described_class.new(email).with(%w[Hello Camille Thanks])).to include('<p>Hello <b>Camille</b></p>').and include('<p>Thanks</p>')
  end

  it 'reads the trimmed reply of a text email and the content of any other message' do
    reply = create(:message, account: account, conversation: conversation, message_type: :incoming, content: "Bonjour\n\n> Hello",
                             content_attributes: { email: { text_content: { quoted: 'Bonjour' } } })
    chat = create(:message, account: account, conversation: conversation, message_type: :incoming, content: 'Salut')

    expect(described_class.new(reply).texts).to eq(['Bonjour'])
    expect(described_class.new(chat).with(['Hi'])).to eq('Hi')
  end
end
