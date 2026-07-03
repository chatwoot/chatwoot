require 'rails_helper'

RSpec.describe Crm::Ai::Evaluator do
  around do |example|
    previous_crm = ENV.fetch('CRM_KANBAN_ENABLED', nil)
    previous_ai = ENV.fetch('CRM_AI_ENABLED', nil)
    previous_attr = ENV.fetch('CRM_AI_ATTR_EXTRACTION', nil)
    ENV['CRM_KANBAN_ENABLED'] = 'true'
    ENV['CRM_AI_ENABLED'] = 'true'
    example.run
  ensure
    previous_crm.nil? ? ENV.delete('CRM_KANBAN_ENABLED') : ENV['CRM_KANBAN_ENABLED'] = previous_crm
    previous_ai.nil? ? ENV.delete('CRM_AI_ENABLED') : ENV['CRM_AI_ENABLED'] = previous_ai
    previous_attr.nil? ? ENV.delete('CRM_AI_ATTR_EXTRACTION') : ENV['CRM_AI_ATTR_EXTRACTION'] = previous_attr
  end

  it 'skips when confidence is below suggestion threshold' do
    account, admin = create_account_and_user
    pipeline, stage = create_crm_pipeline(account: account, user: admin)
    target_stage = create_crm_stage(account: account, pipeline: pipeline, name: 'Proposta', position: 1)
    target_stage.update!(metadata: { 'ai_criteria' => 'Proposta enviada' })
    card = account.crm_cards.create!(
      pipeline: pipeline,
      stage: stage,
      title: 'Lead',
      currency: 'BRL'
    )

    allow(Crm::Ai::CredentialResolver).to receive(:new).and_return(
      instance_double(Crm::Ai::CredentialResolver, configured?: true, resolve: { api_key: 'test', api_base: 'https://api.openai.com' })
    )
    allow(Crm::Ai::StageClassifier).to receive(:new).and_return(
      instance_double(
        Crm::Ai::StageClassifier,
        perform: {
          suggested_stage_id: target_stage.id,
          confidence: 0.5,
          reasoning: 'Baixa confiança',
          model_used: 'gpt-5.4-mini'
        }
      )
    )

    result = described_class.new(card: card).perform
    expect(result.status).to eq(:below_threshold)
    expect(account.crm_ai_stage_suggestions.where(card: card).count).to eq(0)
  end

  it 'creates a pending suggestion when confidence is between thresholds' do
    account, admin = create_account_and_user
    pipeline, stage = create_crm_pipeline(account: account, user: admin)
    target_stage = create_crm_stage(account: account, pipeline: pipeline, name: 'Proposta', position: 1)
    target_stage.update!(metadata: { 'ai_criteria' => 'Proposta enviada' })
    card = account.crm_cards.create!(
      pipeline: pipeline,
      stage: stage,
      title: 'Lead',
      currency: 'BRL'
    )

    allow(Crm::Ai::CredentialResolver).to receive(:new).and_return(
      instance_double(Crm::Ai::CredentialResolver, configured?: true, resolve: { api_key: 'test', api_base: 'https://api.openai.com' })
    )
    allow(Crm::Ai::StageClassifier).to receive(:new).and_return(
      instance_double(
        Crm::Ai::StageClassifier,
        perform: {
          suggested_stage_id: target_stage.id,
          confidence: 0.65,
          reasoning: 'Cliente pediu orçamento',
          model_used: 'gpt-5.4-mini'
        }
      )
    )

    result = described_class.new(card: card).perform
    expect(result.status).to eq(:suggested)
    expect(result.suggestion).to be_pending
    expect(result.suggestion.to_stage_id).to eq(target_stage.id)
  end

  it 'applies extracted attributes even when the stage does not change' do
    ENV.delete('CRM_AI_ATTR_EXTRACTION')
    account, admin = create_account_and_user
    pipeline, stage = create_crm_pipeline(account: account, user: admin)
    pipeline.update!(metadata: { 'ai' => { 'attribute_extraction_enabled' => true, 'attribute_prefix' => 'sw_' } })
    create(
      :custom_attribute_definition,
      account: account,
      attribute_key: 'sw_cidade',
      attribute_model: 'contact_attribute',
      attribute_display_type: 'text'
    )
    inbox = create_crm_inbox(account: account)
    contact = create(:contact, account: account)
    conversation = create_crm_conversation(account: account, inbox: inbox, contact: contact)
    card = account.crm_cards.create!(
      pipeline: pipeline,
      stage: stage,
      title: 'Lead',
      contact: contact,
      primary_conversation: conversation,
      currency: 'BRL'
    )

    allow(Crm::Ai::CredentialResolver).to receive(:new).and_return(
      instance_double(Crm::Ai::CredentialResolver, configured?: true, resolve: { api_key: 'test', api_base: 'https://api.openai.com' })
    )
    classifier = instance_double(
      Crm::Ai::StageClassifier,
      perform: {
        suggested_stage_id: stage.id,
        confidence: 0.95,
        reasoning: 'Permanece no estágio atual',
        value: nil,
        handoff: nil,
        callback_request: nil,
        extracted_attributes: {
          contact: [{ key: 'sw_cidade', value: 'Guarapuava', confidence: 0.9, evidence: 'Sou de Guarapuava' }],
          conversation: []
        },
        model_used: 'gpt-5.4-mini'
      }
    )
    allow(Crm::Ai::StageClassifier).to receive(:new).and_return(classifier)

    result = described_class.new(card: card).perform

    expect(result.status).to eq(:skipped)
    expect(result.error).to eq('same_stage')
    expect(contact.reload.custom_attributes).to include('sw_cidade' => 'Guarapuava')
  end

  it 'passes an empty attribute schema and does not call the applier when the gate is disabled' do
    ENV['CRM_AI_ATTR_EXTRACTION'] = 'false'
    account, admin = create_account_and_user
    pipeline, stage = create_crm_pipeline(account: account, user: admin)
    pipeline.update!(metadata: { 'ai' => { 'attribute_extraction_enabled' => true, 'attribute_prefix' => 'sw_' } })
    card = account.crm_cards.create!(
      pipeline: pipeline,
      stage: stage,
      title: 'Lead',
      currency: 'BRL'
    )

    allow(Crm::Ai::CredentialResolver).to receive(:new).and_return(
      instance_double(Crm::Ai::CredentialResolver, configured?: true, resolve: { api_key: 'test', api_base: 'https://api.openai.com' })
    )
    classifier = instance_double(
      Crm::Ai::StageClassifier,
      perform: {
        suggested_stage_id: stage.id,
        confidence: 0.95,
        reasoning: 'Permanece no estágio atual',
        value: nil,
        handoff: nil,
        callback_request: nil,
        extracted_attributes: {
          contact: [{ key: 'sw_cidade', value: 'Guarapuava', confidence: 0.9, evidence: 'Sou de Guarapuava' }],
          conversation: []
        },
        model_used: 'gpt-5.4-mini'
      }
    )

    expect(Crm::Ai::StageClassifier).to receive(:new).with(hash_including(attribute_schema: { contact: [], conversation: [] }))
                                                      .and_return(classifier)
    expect(Crm::Ai::AttributeExtractorApplier).not_to receive(:new)

    described_class.new(card: card).perform
  end
end
