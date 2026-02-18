# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Ticket do
  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:contact).optional }
    it { is_expected.to belong_to(:conversation).optional }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:subject) }
  end

  describe '#external_id_for' do
    let(:ticket) { create(:ticket, external_ids: { 'zoho' => 'abc123' }) }

    it 'returns the external id for the given provider' do
      expect(ticket.external_id_for('zoho')).to eq('abc123')
    end

    it 'returns nil for unknown providers' do
      expect(ticket.external_id_for('salesforce')).to be_nil
    end
  end

  describe '#store_external_id' do
    let(:ticket) { create(:ticket) }

    it 'stores and persists the external id' do
      ticket.store_external_id('zoho', 'ticket_456')
      ticket.reload
      expect(ticket.external_ids['zoho']).to eq('ticket_456')
    end

    it 'preserves existing external ids when adding new ones' do
      ticket.store_external_id('zoho', 'z123')
      ticket.store_external_id('salesforce', 's456')
      ticket.reload
      expect(ticket.external_ids).to eq('zoho' => 'z123', 'salesforce' => 's456')
    end
  end
end
