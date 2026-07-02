require 'rails_helper'

RSpec.describe Conversations::EventDataPresenter do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:contact) { create(:contact, account: account) }
  let(:inbox) { create_crm_inbox(account: account, members: [admin]) }
  let(:conversation) { create_crm_conversation(account: account, inbox: inbox, contact: contact) }

  def build_card(handoff_pointer)
    pipeline, stage = create_crm_pipeline(account: account, user: admin)
    account.crm_cards.create!(
      pipeline: pipeline,
      stage: stage,
      inbox: inbox,
      contact: contact,
      primary_conversation: conversation,
      title: 'Lead badge lista',
      metadata: { 'ai' => { 'handoff' => handoff_pointer } }
    )
  end

  it 'exposes handoff_invite for an open invite cycle when CRM AI is on' do
    with_modified_env CRM_KANBAN_ENABLED: 'true', CRM_AI_ENABLED: 'true' do
      invited_at = 5.minutes.ago.change(usec: 0)
      due_at = invited_at + 15.minutes
      build_card('cycle_id' => 1, 'invited_at' => invited_at.iso8601, 'pickup_due_at' => due_at.iso8601)

      invite = described_class.new(conversation).push_data[:handoff_invite]

      expect(invite[:pickup_due_at]).to eq(due_at.to_i)
    end
  end

  it 'omits handoff_invite once the cycle is picked up' do
    with_modified_env CRM_KANBAN_ENABLED: 'true', CRM_AI_ENABLED: 'true' do
      build_card(
        'cycle_id' => 1, 'invited_at' => 20.minutes.ago.iso8601, 'picked_up_at' => 5.minutes.ago.iso8601
      )

      expect(described_class.new(conversation).push_data[:handoff_invite]).to be_nil
    end
  end

  it 'skips the lookup entirely when CRM AI is disabled' do
    with_modified_env CRM_AI_ENABLED: 'false' do
      expect(described_class.new(conversation).push_data[:handoff_invite]).to be_nil
    end
  end
end
