require 'rails_helper'

RSpec.describe Captain::Conversation::MessageText do
  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account) }
  let(:html) do
    '<div style="display:none">Preheader</div><title>Old thread</title><style>p {}</style>' \
      '<p>Bonjour <b>Camille</b>, <a href="/x">voir la commande</a></p><blockquote>Ancien message</blockquote>' \
      '<div class="gmail_quote"><div class="gmail_attr">Le mardi, Support a écrit :</div></div>' \
      '<div id="divRplyFwdMsg"><b>From:</b> Support</div><div>Old Outlook thread</div>'
  end
  let(:email) do
    create(:message, account: account, conversation: conversation, message_type: :incoming, content: 'Bonjour Camille',
                     content_attributes: { email: { html_content: { full: html } } })
  end
  let(:chat) do
    create(:message, account: account, conversation: conversation, message_type: :incoming, content: 'Celui-ci met quatre secondes à charger.')
  end

  it 'reads a plain message as one text and detects its language' do
    text = described_class.new(chat)

    expect(text.texts).to eq(['Celui-ci met quatre secondes à charger.'])
    expect(text.language).to eq('fr')
    expect(text.original).to eq(chat.content)
  end

  it 'reads only the visible text nodes of an html email' do
    expect(described_class.new(email).texts).to eq(['Bonjour', 'Camille', 'voir la commande'])
  end

  it 'rebuilds the email with translated nodes and the markup untouched' do
    translated = described_class.new(email).translated(0 => 'Hello', 1 => 'Camille', 2 => 'see the order')

    expect(translated).to include('<p>Hello <b>Camille</b>, <a href="/x">see the order</a></p>')
    expect(translated).to include('<blockquote>Ancien message</blockquote>', '<div style="display:none">Preheader</div>')
  end

  it 'returns the original when the translation comes back unchanged or empty' do
    expect(described_class.new(chat).translated(0 => ' Celui-ci met quatre secondes à charger. ')).to eq(chat.content)
    expect(described_class.new(chat).translated({})).to eq(chat.content)
  end
end
