require 'rails_helper'

describe SlaPolicyDrop do
  subject(:sla_policy_drop) { described_class.new(sla_policy) }

  let!(:sla_policy) { create(:sla_policy) }

  it 'returns name' do
    expect(sla_policy_drop.name).to eq sla_policy.name
  end

  it 'returns description' do
    expect(sla_policy_drop.description).to eq sla_policy.description
  end
end
