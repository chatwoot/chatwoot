require 'rails_helper'

RSpec.describe Crm::MetaCapi::PayloadBuilder do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account, role: :administrator) }
  let(:pipeline) { account.crm_pipelines.create!(name: 'P', created_by: user, status: :active) }
  let(:stage) { account.crm_pipeline_stages.create!(pipeline: pipeline, name: 'S', position: 0) }

  def build_card(attrs = {})
    account.crm_cards.create!({ pipeline: pipeline, stage: stage, title: 'Card', currency: 'BRL' }.merge(attrs))
  end

  describe '.canonical_event_name' do
    it 'maps won to the native Purchase event' do
      expect(described_class.canonical_event_name(event_type: 'won', stage_type: nil)).to eq('Purchase')
    end

    it 'maps lost to the OrderCanceled proxy event' do
      expect(described_class.canonical_event_name(event_type: 'lost', stage_type: 'ignored')).to eq('OrderCanceled')
    end

    it 'uses the stage funnel type for movement events' do
      expect(described_class.canonical_event_name(event_type: 'move', stage_type: 'QualifiedLead')).to eq('QualifiedLead')
      expect(described_class.canonical_event_name(event_type: 'create', stage_type: 'LeadSubmitted')).to eq('LeadSubmitted')
    end

    it 'returns nil for a movement without a configured stage type' do
      expect(described_class.canonical_event_name(event_type: 'move', stage_type: nil)).to be_nil
    end

    it 'returns nil for lifecycle events with no native CAPI mapping' do
      expect(described_class.canonical_event_name(event_type: 'reopen', stage_type: 'QualifiedLead')).to be_nil
      expect(described_class.canonical_event_name(event_type: 'archive', stage_type: nil)).to be_nil
    end
  end

  describe '.build' do
    it 'builds a business_messaging event carrying the ctwa_clid and waba id' do
      card = build_card(value_cents: 50_000, external_id: 'EXT-9')

      event = described_class.build(card: card, event_name: 'Purchase', event_type: 'won', ctwa_clid: 'CLID1', waba_id: 'WABA1')

      expect(event['event_name']).to eq('Purchase')
      expect(event['action_source']).to eq('business_messaging')
      expect(event['messaging_channel']).to eq('whatsapp')
      expect(event['user_data']).to eq('whatsapp_business_account_id' => 'WABA1', 'ctwa_clid' => 'CLID1')
      expect(event['custom_data']).to include('value' => 500.0, 'currency' => 'BRL', 'order_id' => 'EXT-9')
    end

    it 'omits value and currency for a zero-value funnel movement' do
      card = build_card(value_cents: 0)

      event = described_class.build(card: card, event_name: 'QualifiedLead', event_type: 'move', ctwa_clid: 'CLID1', waba_id: nil)

      expect(event).not_to have_key('custom_data')
      expect(event['user_data']).to eq('ctwa_clid' => 'CLID1')
    end

    it 'anchors event_time to closed_at for result events' do
      closed = 2.days.ago.change(usec: 0)
      card = build_card(status: :won, value_cents: 100)
      card.update!(closed_at: closed)

      event = described_class.build(card: card, event_name: 'Purchase', event_type: 'won', ctwa_clid: 'CLID1', waba_id: 'WABA1')

      expect(event['event_time']).to eq(closed.to_i)
      expect(event['event_id']).to eq("#{card.id}:won:#{card.stage_id}:#{closed.to_i}")
    end

    it 'anchors event_time to entered_stage_at for movement events' do
      entered = 3.hours.ago.change(usec: 0)
      card = build_card
      card.update!(entered_stage_at: entered)

      event = described_class.build(card: card, event_name: 'QualifiedLead', event_type: 'move', ctwa_clid: 'CLID1', waba_id: 'WABA1')

      expect(event['event_time']).to eq(entered.to_i)
    end
  end
end
