# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Aloo::AssistantInbox do
  subject(:assistant_inbox) { build(:aloo_assistant_inbox) }

  describe 'associations' do
    it { is_expected.to belong_to(:assistant).class_name('Aloo::Assistant') }
    it { is_expected.to belong_to(:inbox) }
  end

  describe 'validations' do
    subject { create(:aloo_assistant_inbox) }

    it { is_expected.to validate_uniqueness_of(:inbox_id).with_message('already has an assistant assigned') }

    context 'when inbox already has an assistant' do
      let(:inbox) { create(:inbox) }
      let!(:existing_assignment) { create(:aloo_assistant_inbox, inbox: inbox) }

      it 'prevents duplicate assignment' do
        new_assignment = build(:aloo_assistant_inbox, inbox: inbox)
        expect(new_assignment).not_to be_valid
        expect(new_assignment.errors[:inbox_id]).to include('already has an assistant assigned')
      end
    end
  end

  describe 'scopes' do
    describe '.active' do
      let!(:active_assignment) { create(:aloo_assistant_inbox, active: true) }
      let!(:inactive_assignment) { create(:aloo_assistant_inbox, :inactive) }

      it 'returns only active assistant inboxes' do
        expect(described_class.active).to include(active_assignment)
        expect(described_class.active).not_to include(inactive_assignment)
      end
    end
  end

  describe 'delegation' do
    let(:account) { create(:account) }
    let(:assistant) { create(:aloo_assistant, account: account) }
    let(:assistant_inbox) { create(:aloo_assistant_inbox, assistant: assistant) }

    it 'delegates account to assistant' do
      expect(assistant_inbox.account).to eq(account)
    end

    it 'delegates account_id to assistant' do
      expect(assistant_inbox.account_id).to eq(account.id)
    end
  end
end
