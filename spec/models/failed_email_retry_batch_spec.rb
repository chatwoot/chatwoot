require 'rails_helper'

RSpec.describe FailedEmailRetryBatch do
  describe 'validations' do
    it 'accepts only supported lookback periods' do
      expect(build(:failed_email_retry_batch, lookback_hours: 2)).to be_valid
      expect(build(:failed_email_retry_batch, lookback_hours: 3)).not_to be_valid
    end
  end

  describe '.preview_for' do
    let(:range_end) { Time.zone.parse('2026-07-26 12:00:00 UTC') }
    let(:active_account) { create(:account) }
    let(:active_inbox) { create(:channel_email, account: active_account).inbox }
    let(:suspended_account) { create(:account, status: :suspended) }
    let(:suspended_inbox) { create(:channel_email, account: suspended_account).inbox }
    let(:widget_inbox) { create(:inbox, account: active_account) }

    before do
      create(
        :message,
        account: active_account,
        inbox: active_inbox,
        conversation: create(:conversation, account: active_account, inbox: active_inbox),
        status: :failed,
        message_type: :outgoing,
        created_at: range_end - 30.minutes,
        updated_at: range_end - 20.minutes
      )
      create(
        :message,
        account: suspended_account,
        inbox: suspended_inbox,
        conversation: create(:conversation, account: suspended_account, inbox: suspended_inbox),
        status: :failed,
        message_type: :outgoing,
        created_at: range_end - 20.minutes,
        updated_at: range_end - 10.minutes
      )
      create(
        :message,
        account: active_account,
        inbox: active_inbox,
        conversation: create(:conversation, account: active_account, inbox: active_inbox),
        status: :sent,
        message_type: :outgoing,
        created_at: range_end - 30.minutes
      )
      create(
        :message,
        account: active_account,
        inbox: active_inbox,
        conversation: create(:conversation, account: active_account, inbox: active_inbox),
        status: :failed,
        message_type: :incoming,
        created_at: range_end - 30.minutes
      )
      create(
        :message,
        account: active_account,
        inbox: widget_inbox,
        conversation: create(:conversation, account: active_account, inbox: widget_inbox),
        status: :failed,
        message_type: :outgoing,
        created_at: range_end - 30.minutes
      )
      create(
        :message,
        account: active_account,
        inbox: active_inbox,
        conversation: create(:conversation, account: active_account, inbox: active_inbox),
        status: :failed,
        message_type: :outgoing,
        created_at: range_end - 2.hours
      )
      create(
        :message,
        account: active_account,
        inbox: active_inbox,
        conversation: create(:conversation, account: active_account, inbox: active_inbox),
        status: :failed,
        message_type: :outgoing,
        created_at: range_end - 10.minutes,
        updated_at: range_end + 1.minute
      )
    end

    it 'counts failed outgoing email messages and separates suspended accounts' do
      preview = described_class.preview_for(lookback_hours: 1, range_end: range_end)

      expect(preview).to include(
        range_start: range_end - 1.hour,
        range_end: range_end,
        candidate_count: 2,
        eligible_count: 1,
        suspended_count: 1
      )
    end

    it 'rejects unsupported lookback periods' do
      expect { described_class.preview_for(lookback_hours: 3, range_end: range_end) }
        .to raise_error(ArgumentError, 'Unsupported lookback: 3')
    end
  end
end
