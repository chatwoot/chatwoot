require 'rails_helper'

RSpec.describe Crm::Ai::ContextBuilder do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:pipeline) { create_crm_pipeline(account: account, user: admin).first }
  let(:stage) { pipeline.stages.first }
  let(:inbox) { create_crm_inbox(account: account) }
  let(:contact) { create(:contact, account: account) }
  let(:conversation) { create_crm_conversation(account: account, inbox: inbox, contact: contact) }
  let(:card) do
    account.crm_cards.create!(
      pipeline: pipeline,
      stage: stage,
      title: 'Lead',
      contact: contact,
      primary_conversation: conversation,
      currency: 'BRL'
    )
  end

  describe '#perform known_attributes' do
    it 'exposes stored values, dropping blanks but keeping false (checkbox)' do
      contact.update!(custom_attributes: { 'sw_cidade' => 'Guarapuava', 'sw_optin' => false, 'sw_vazio' => '' })
      conversation.update!(custom_attributes: { 'sw_agenda' => 'confirmada' })

      known = described_class.new(card: card).perform[:known_attributes]

      expect(known[:contact]).to eq('sw_cidade' => 'Guarapuava', 'sw_optin' => false)
      expect(known[:conversation]).to eq('sw_agenda' => 'confirmada')
    end

    it 'returns empty groups when nothing is stored' do
      contact.update!(custom_attributes: {})
      conversation.update!(custom_attributes: {})

      known = described_class.new(card: card).perform[:known_attributes]

      expect(known).to eq(contact: {}, conversation: {})
    end
  end
end
