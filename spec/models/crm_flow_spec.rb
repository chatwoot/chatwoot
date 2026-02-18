# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CrmFlow do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_inclusion_of(:trigger_type).in_array(described_class::TRIGGER_TYPES) }
    it { is_expected.to validate_inclusion_of(:scope_type).in_array(described_class::SCOPE_TYPES) }
  end

  describe 'TRIGGER_TYPES' do
    it 'includes ticket_created' do
      expect(described_class::TRIGGER_TYPES).to include('ticket_created')
    end
  end

  describe '.resolve_for' do
    let(:account) { create(:account) }
    let!(:global_flow) { create(:crm_flow, account: account, trigger_type: 'ticket_created', scope_type: 'global') }

    it 'returns the global flow for the trigger type' do
      result = described_class.resolve_for(account_id: account.id, trigger_type: 'ticket_created')
      expect(result).to eq(global_flow)
    end

    it 'returns nil when no flow matches' do
      result = described_class.resolve_for(account_id: account.id, trigger_type: 'quote_request')
      expect(result).to be_nil
    end

    it 'does not return inactive flows' do
      global_flow.update!(active: false)
      result = described_class.resolve_for(account_id: account.id, trigger_type: 'ticket_created')
      expect(result).to be_nil
    end
  end

  describe 'actions validation' do
    it 'requires at least one action' do
      flow = build(:crm_flow, actions: [])
      expect(flow).not_to be_valid
      expect(flow.errors[:actions]).to include('must have at least one action')
    end
  end
end
