require 'rails_helper'

describe Conversations::UnreadCountService do
  let!(:account) { create(:account) }
  let!(:admin) { create(:user, account: account, role: :administrator) }
  let!(:agent) { create(:user, account: account, role: :agent) }
  let!(:inbox_1) { create(:inbox, account: account) }
  let!(:inbox_2) { create(:inbox, account: account) }

  before do
    create(:inbox_member, user: agent, inbox: inbox_1)
  end

  describe '#perform' do
    it 'returns correct hash structure' do
      result = described_class.new(account: account, user: admin).perform

      expect(result).to have_key(:by_inbox)
      expect(result).to have_key(:by_label)
      expect(result).to have_key(:by_status)
      expect(result).to have_key(:total)
    end

    context 'when there are no unread conversations' do
      it 'returns zeros' do
        result = described_class.new(account: account, user: admin).perform

        expect(result[:by_inbox]).to eq({})
        expect(result[:by_label]).to eq({})
        expect(result[:by_status]).to eq({ all: 0, mine: 0, unassigned: 0 })
        expect(result[:total]).to eq(0)
      end
    end

    context 'when there are unread conversations' do
      let!(:unread_conv_1) { create(:conversation, account: account, inbox: inbox_1, has_unread_messages: true, status: :open) }
      let!(:unread_conv_2) { create(:conversation, account: account, inbox: inbox_1, has_unread_messages: true, status: :pending) }
      let!(:unread_conv_3) { create(:conversation, account: account, inbox: inbox_2, has_unread_messages: true, status: :open) }
      let!(:read_conv) { create(:conversation, account: account, inbox: inbox_1, has_unread_messages: false, status: :open) }
      let!(:resolved_conv) { create(:conversation, account: account, inbox: inbox_1, has_unread_messages: true, status: :resolved) }

      it 'counts only conversations with has_unread_messages: true' do
        result = described_class.new(account: account, user: admin).perform

        expect(result[:total]).to eq(3)
      end

      it 'does not count resolved conversations' do
        result = described_class.new(account: account, user: admin).perform

        expect(result[:total]).to eq(3)
      end

      it 'groups counts correctly by inbox_id' do
        result = described_class.new(account: account, user: admin).perform

        expect(result[:by_inbox][inbox_1.id]).to eq(2)
        expect(result[:by_inbox][inbox_2.id]).to eq(1)
      end

      describe 'by_status counts' do
        before do
          unread_conv_1.update!(assignee: admin)
          unread_conv_2.update!(assignee: agent)
        end

        it 'returns correct all count' do
          result = described_class.new(account: account, user: admin).perform

          expect(result[:by_status][:all]).to eq(3)
        end

        it 'returns correct mine count for current user' do
          result = described_class.new(account: account, user: admin).perform

          expect(result[:by_status][:mine]).to eq(1)
        end

        it 'returns correct unassigned count' do
          result = described_class.new(account: account, user: admin).perform

          expect(result[:by_status][:unassigned]).to eq(1)
        end
      end
    end

    context 'with labels' do
      let!(:unread_conv_1) { create(:conversation, account: account, inbox: inbox_1, has_unread_messages: true, status: :open) }
      let!(:unread_conv_2) { create(:conversation, account: account, inbox: inbox_1, has_unread_messages: true, status: :open) }

      before do
        unread_conv_1.update_labels('support')
        unread_conv_2.update_labels('support,billing')
      end

      it 'groups counts correctly by label title' do
        result = described_class.new(account: account, user: admin).perform

        expect(result[:by_label]['support']).to eq(2)
        expect(result[:by_label]['billing']).to eq(1)
      end
    end

    context 'with permission filtering' do
      let!(:unread_conv_inbox_1) { create(:conversation, account: account, inbox: inbox_1, has_unread_messages: true, status: :open) }
      let!(:unread_conv_inbox_2) { create(:conversation, account: account, inbox: inbox_2, has_unread_messages: true, status: :open) }

      it 'returns all inboxes for administrators' do
        result = described_class.new(account: account, user: admin).perform

        expect(result[:total]).to eq(2)
        expect(result[:by_inbox].keys).to contain_exactly(inbox_1.id, inbox_2.id)
      end

      it 'filters by inbox membership for agents' do
        result = described_class.new(account: account, user: agent).perform

        expect(result[:total]).to eq(1)
        expect(result[:by_inbox].keys).to contain_exactly(inbox_1.id)
      end
    end
  end
end
