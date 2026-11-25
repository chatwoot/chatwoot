require 'rails_helper'

describe CsatSurveys::LiquidResolver do
  subject(:resolver) { described_class.new(conversation: conversation) }

  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:contact) { create(:contact, account: account, name: 'Joana') }
  let(:contact_inbox) { create(:contact_inbox, contact: contact, inbox: inbox) }
  let(:conversation) { create(:conversation, contact: contact, contact_inbox: contact_inbox, inbox: inbox, account: account) }

  it 'renders a drop against the conversation' do
    expect(resolver.resolve('{{contact.name}}')).to eq 'Joana'
  end

  it 'returns a blank value untouched' do
    expect(resolver.resolve('')).to eq ''
  end

  it 'keeps the literal when the template renders to nothing' do
    expect(resolver.resolve('{{contact.nonexistent}}')).to eq '{{contact.nonexistent}}'
  end

  # A broken value is admin copy, not a reason to lose the survey.
  it 'keeps the literal when the template does not parse' do
    expect(resolver.resolve('{% if %}')).to eq '{% if %}'
  end
end
