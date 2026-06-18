require 'rails_helper'

RSpec.describe Synapseos::LeadLifecycleMirror do
  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account) }
  let(:lead) do
    l = create(:synapseos_lead, account: account, conversation: conversation)
    l.update_columns(estado: 'quer', next_action_at: 2.hours.from_now,
                     modelo_interesse: 'A4', tem_troca: true,
                     forma_pagamento: 'financiamento', urgencia: 'alta',
                     retomada_at: nil)
    l
  end

  it 'mirrors business fields into conversation custom_attributes' do
    described_class.new(lead: lead, from_estado: nil, signal: :quer).call
    attrs = conversation.reload.custom_attributes
    expect(attrs['lead_estado']).to eq('quer')
    expect(attrs['lead_modelo_interesse']).to eq('A4')
    expect(attrs['lead_tem_troca']).to be(true)
    expect(attrs['lead_forma_pagamento']).to eq('financiamento')
    expect(attrs['lead_urgencia']).to eq('alta')
  end

  it 'applies the state label and removes prior state labels' do
    conversation.update_labels(['lead:sem-resposta', 'vip'])
    described_class.new(lead: lead, from_estado: 'sem_resposta', signal: :quer).call
    labels = conversation.reload.label_list
    expect(labels).to include('lead:quer')
    expect(labels).to include('vip')
    expect(labels).not_to include('lead:sem-resposta')
  end

  it 'creates a CrmEvent when estado changed' do
    expect do
      described_class.new(lead: lead, from_estado: 'sem_resposta', signal: :quer).call
    end.to change { Synapseos::CrmEvent.where(event_type: 'lead_state_changed').count }.by(1)
  end

  it 'does not create a CrmEvent when estado is unchanged (idempotent)' do
    expect do
      described_class.new(lead: lead, from_estado: 'quer', signal: :quer).call
    end.not_to change { Synapseos::CrmEvent.where(event_type: 'lead_state_changed').count }
  end

  it 'does not resolve the conversation for non-terminal states' do
    described_class.new(lead: lead, from_estado: nil, signal: :quer).call
    expect(conversation.reload.status).to eq('open')
  end

  it 'resolves the conversation only on terminal nao_quer' do
    lead.update_columns(estado: 'nao_quer', motivo: 'x', next_action_at: nil)
    described_class.new(lead: lead, from_estado: 'quer', signal: :nao_quer).call
    expect(conversation.reload.status).to eq('resolved')
  end
end
