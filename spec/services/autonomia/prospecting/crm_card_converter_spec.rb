require 'rails_helper'

RSpec.describe Autonomia::Prospecting::CrmCardConverter do
  let(:account) { create(:account) }
  let(:user) { create(:user, :administrator, account: account) }
  let(:pipeline) { create_crm_pipeline(account: account, user: user).first }
  let(:stage) { pipeline.stages.first }
  let(:lead) do
    Autonomia::Prospecting::Lead.create!(
      account: account,
      provider: 'mock',
      provider_place_id: 'mock-place-1',
      name: 'Alpha Restaurante',
      phone: '+55 11 99999-8888',
      website: 'https://alpha.example.com',
      address: 'Rua das Flores, 123',
      city: 'Sao Paulo',
      state: 'SP',
      country: 'BR',
      category: 'Restaurante',
      rating: 4.7,
      reviews_count: 231
    )
  end

  before do
    allow(Crm::Config).to receive(:enabled?).and_return(true)
  end

  it 'creates a CRM card and links it to the prospecting lead' do
    result = described_class.new(lead: lead, user: user, pipeline_id: pipeline.id, stage_id: stage.id).perform

    expect(result.created).to be(true)
    expect(result.card).to be_persisted
    expect(result.card.pipeline).to eq(pipeline)
    expect(result.card.stage).to eq(stage)
    expect(result.card.contact_id).to be_present
    expect(result.card.external_id).to eq("autonomia_prospecting_lead:#{lead.id}")
    expect(result.card.metadata.dig('autonomia_prospecting', 'lead_id')).to eq(lead.id)
    expect(result.lead.crm_card_id).to eq(result.card.id)
    expect(result.lead.contact_id).to eq(result.card.contact_id)
  end

  it 'returns the linked card without creating duplicates' do
    first = described_class.new(lead: lead, user: user, pipeline_id: pipeline.id, stage_id: stage.id).perform
    second = described_class.new(lead: lead.reload, user: user, pipeline_id: pipeline.id, stage_id: stage.id).perform

    expect(second.created).to be(false)
    expect(second.card).to eq(first.card)
    expect(account.crm_cards.count).to eq(1)
  end

  it 'rejects stages from another pipeline' do
    other_pipeline, other_stage = create_crm_pipeline(account: account, user: user, name: 'Outro funil')

    expect do
      described_class.new(lead: lead, user: user, pipeline_id: pipeline.id, stage_id: other_stage.id).perform
    end.to raise_error(ActiveRecord::RecordNotFound)

    expect(other_pipeline.cards.count).to eq(0)
  end
end
