require 'rails_helper'

RSpec.describe Crm::Ai::AttributeExtractorApplier do
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

  def create_attribute(key:, model:, type:, values: nil)
    create(
      :custom_attribute_definition,
      account: account,
      attribute_key: key,
      attribute_model: model,
      attribute_display_type: type,
      attribute_values: values
    )
  end

  it 'fills empty contact and conversation attributes with coerced values and audit metadata' do
    create_attribute(key: 'sw_cidade', model: 'contact_attribute', type: 'text')
    create_attribute(key: 'sw_valor_conta_luz', model: 'contact_attribute', type: 'number')
    create_attribute(key: 'sw_decisor', model: 'contact_attribute', type: 'list', values: ['Sim, decide', 'Há outros decisores'])
    create_attribute(key: 'sw_agenda_confirmada', model: 'conversation_attribute', type: 'checkbox')

    result = described_class.new(
      card: card,
      prefix: 'sw_',
      extracted_attributes: {
        contact: [
          { key: 'sw_cidade', value: 'Guarapuava', confidence: 0.9, evidence: 'Sou de Guarapuava' },
          { key: 'sw_valor_conta_luz', value: '3000.0', confidence: 0.9, evidence: 'conta dá 3 mil' },
          { key: 'sw_decisor', value: 'Há outros decisores', confidence: 0.8, evidence: 'decido com meu sócio' }
        ],
        conversation: [
          { key: 'sw_agenda_confirmada', value: false, confidence: 0.9, evidence: 'ainda não confirmei agenda' }
        ]
      }
    ).perform

    expect(result.rejected).to be_empty
    expect(contact.reload.custom_attributes).to include(
      'sw_cidade' => 'Guarapuava',
      'sw_valor_conta_luz' => 3000,
      'sw_decisor' => 'Há outros decisores'
    )
    expect(conversation.reload.custom_attributes).to include('sw_agenda_confirmada' => false)
    expect(card.reload.metadata.dig('ai', 'extracted_attributes', 'sw_cidade')).to include(
      'target' => 'contact',
      'source' => 'ai',
      'evidence' => 'Sou de Guarapuava'
    )
  end

  it 'does not overwrite an already filled custom attribute' do
    create_attribute(key: 'sw_cidade', model: 'contact_attribute', type: 'text')
    contact.update!(custom_attributes: { 'sw_cidade' => 'Curitiba' })

    result = described_class.new(
      card: card,
      prefix: 'sw_',
      extracted_attributes: {
        contact: [{ key: 'sw_cidade', value: 'Guarapuava', confidence: 0.95, evidence: 'Sou de Guarapuava' }],
        conversation: []
      }
    ).perform

    expect(contact.reload.custom_attributes['sw_cidade']).to eq('Curitiba')
    expect(result.rejected).to include(hash_including(key: 'sw_cidade', reason: 'already_filled'))
  end

  it 'rejects unknown keys, non-whitelisted keys, low confidence, invalid numbers and invalid list values' do
    create_attribute(key: 'sw_valor_conta_luz', model: 'contact_attribute', type: 'number')
    create_attribute(key: 'sw_decisor', model: 'contact_attribute', type: 'list', values: ['Sim, decide'])
    create_attribute(key: 'other_city', model: 'contact_attribute', type: 'text')

    result = described_class.new(
      card: card,
      prefix: 'sw_',
      extracted_attributes: {
        contact: [
          { key: 'sw_inexistente', value: 'x', confidence: 0.9, evidence: 'x' },
          { key: 'other_city', value: 'Guarapuava', confidence: 0.9, evidence: 'cidade' },
          { key: 'sw_valor_conta_luz', value: 'tres mil', confidence: 0.9, evidence: 'valor' },
          { key: 'sw_decisor', value: 'Há outros decisores', confidence: 0.9, evidence: 'decisor' },
          { key: 'sw_valor_conta_luz', value: 3000, confidence: 0.4, evidence: 'valor' }
        ],
        conversation: []
      }
    ).perform

    expect(contact.reload.custom_attributes).to be_empty
    expect(result.rejected).to include(
      hash_including(key: 'sw_inexistente', reason: 'unknown_key'),
      hash_including(key: 'other_city', reason: 'not_whitelisted'),
      hash_including(key: 'sw_valor_conta_luz', reason: 'invalid_value'),
      hash_including(key: 'sw_decisor', reason: 'invalid_value'),
      hash_including(key: 'sw_valor_conta_luz', reason: 'low_confidence')
    )
  end

  it 'rejects a key sent in the wrong contact/conversation group' do
    create_attribute(key: 'sw_cidade', model: 'contact_attribute', type: 'text')

    result = described_class.new(
      card: card,
      prefix: 'sw_',
      extracted_attributes: {
        contact: [],
        conversation: [{ key: 'sw_cidade', value: 'Guarapuava', confidence: 0.9, evidence: 'Sou de Guarapuava' }]
      }
    ).perform

    expect(conversation.reload.custom_attributes).to be_empty
    expect(result.rejected).to include(hash_including(target: 'conversation', key: 'sw_cidade', reason: 'unknown_key'))
  end
end
