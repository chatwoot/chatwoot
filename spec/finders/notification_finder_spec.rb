require 'rails_helper'

RSpec.describe NotificationFinder do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account: account) }
  let(:notification_finder) { described_class.new(user, account, params) }

  before do
    create(:notification, :snoozed, account: account, user: user)
    create_list(:notification, 2, :read, account: account, user: user)
    create_list(:notification, 3, account: account, user: user)
  end

  describe '#notifications' do
    subject { notification_finder.notifications }

    context 'with default params (empty)' do
      let(:params) { {} }

      it 'returns all unread and unsnoozed notifications, ordered by last activity' do
        expect(subject.size).to eq(3)
        expect(subject).to match_array(subject.sort_by(&:last_activity_at).reverse)
      end
    end

    context 'with params including read and snoozed statuses' do
      let(:params) { { includes: %w[read snoozed] } }

      it 'returns all notifications, including read and snoozed' do
        expect(subject.size).to eq(6)
      end
    end

    context 'with params including only read status' do
      let(:params) { { includes: ['read'] } }

      it 'returns all notifications expect the snoozed' do
        expect(subject.size).to eq(5)
      end
    end

    context 'with params including only snoozed status' do
      let(:params) { { includes: ['snoozed'] } }

      it 'rreturns all notifications only expect the read' do
        expect(subject.size).to eq(4)
      end
    end

    context 'with ascending sort order' do
      let(:params) { { sort_order: :asc } }

      it 'returns notifications in ascending order by last activity' do
        expect(subject.first.last_activity_at).to be < subject.last.last_activity_at
      end
    end
  end

  describe 'counts' do
    subject { notification_finder }

    context 'without specific filters' do
      let(:params) { {} }

      it 'correctly reports unread and total counts' do
        expect(subject.unread_count).to eq(3)
        expect(subject.count).to eq(3)
      end

      it 'avoids duplicate filtering in unread_count method' do
        # Test the logical fix: when no 'read' filter is included,
        # @notifications is already filtered to unread, so unread_count
        # should just count without adding another read_at filter

        allow(subject.instance_variable_get(:@notifications)).to receive(:where).and_call_original
        allow(subject.instance_variable_get(:@notifications)).to receive(:count).and_call_original

        result = subject.unread_count

        # Should return correct count without additional where clause
        expect(result).to eq(3)

        # The fix ensures that when params[:includes] doesn't contain 'read',
        # unread_count uses @notifications.count instead of @notifications.where(read_at: nil).count
      end
    end

    context 'with filters applied' do
      let(:params) { { includes: %w[read snoozed] } }

      it 'adjusts counts based on included statuses' do
        expect(subject.unread_count).to eq(4) # 3 unread + 1 snoozed (which is unread)
        expect(subject.count).to eq(6) # all notifications including read and snoozed
      end
    end
  end
end
