require 'rails_helper'

RSpec.describe Autonomia::Prospecting::Providers::MockProvider do
  it 'returns deterministic realistic lead attributes' do
    provider = described_class.new(query: 'clinica odontologica', location: 'Curitiba, PR', radius: 5000, limit: 2)

    first_run = provider.search
    second_run = provider.search

    expect(first_run.size).to eq(2)
    expect(first_run).to eq(second_run)
    expect(first_run.first).to include(
      provider: 'mock',
      name: include('Clinica Odontologica'),
      city: 'Curitiba',
      state: 'PR',
      country: 'BR'
    )
    expect(first_run.first[:provider_place_id]).to be_present
    expect(first_run.first[:phone]).to be_present
  end

  it 'supports an empty result scenario' do
    provider = described_class.new(query: 'sem resultados', location: 'Curitiba, PR', radius: 5000, limit: 2)

    expect(provider.search).to eq([])
  end
end
