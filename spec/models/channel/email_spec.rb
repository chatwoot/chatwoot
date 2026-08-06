# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join 'spec/models/concerns/reauthorizable_shared.rb'

RSpec.describe Channel::Email do
  let(:channel) { create(:channel_email) }

  describe 'concerns' do
    it_behaves_like 'reauthorizable'

    context 'when prompt_reauthorization!' do
      it 'calls channel notifier mail for email' do
        admin_mailer = double
        mailer_double = double
        expect(AdministratorNotifications::ChannelNotificationsMailer).to receive(:with).and_return(admin_mailer)
        expect(admin_mailer).to receive(:email_disconnect).with(channel.inbox).and_return(mailer_double)
        expect(mailer_double).to receive(:deliver_later)
        channel.prompt_reauthorization!
      end
    end
  end

  it 'has a valid name' do
    expect(channel.name).to eq('Email')
  end

  context 'when microsoft?' do
    it 'returns false' do
      expect(channel.microsoft?).to be(false)
    end

    it 'returns true' do
      channel.provider = 'microsoft'
      expect(channel.microsoft?).to be(true)
    end
  end

  describe 'imap fetch backoff' do
    describe '#imap_fetch_paused?' do
      it 'returns false when paused_till is not set' do
        expect(channel.imap_fetch_paused?).to be(false)
      end

      it 'returns false when paused_till is in the past' do
        channel.update!(imap_fetch_paused_till: 5.minutes.ago)
        expect(channel.imap_fetch_paused?).to be(false)
      end

      it 'returns true when paused_till is in the future' do
        channel.update!(imap_fetch_paused_till: 5.minutes.from_now)
        expect(channel.imap_fetch_paused?).to be(true)
      end
    end

    describe '#imap_fetch_error!' do
      it 'does not pause on the first two failures' do
        2.times { channel.imap_fetch_error! }

        expect(channel.reload.imap_fetch_error_count).to eq(2)
        expect(channel.imap_fetch_paused_till).to be_nil
      end

      it 'pauses for 5 minutes on the third failure' do
        3.times { channel.imap_fetch_error! }

        expect(channel.reload.imap_fetch_error_count).to eq(3)
        expect(channel.imap_fetch_paused_till).to be_within(10.seconds).of(5.minutes.from_now)
      end

      it 'pauses for 15 minutes on the fourth failure' do
        4.times { channel.imap_fetch_error! }

        expect(channel.reload.imap_fetch_paused_till).to be_within(10.seconds).of(15.minutes.from_now)
      end

      it 'increments from the persisted count when the in-memory value is stale' do
        stale_channel = described_class.find(channel.id)
        channel.imap_fetch_error!
        stale_channel.imap_fetch_error!

        expect(channel.reload.imap_fetch_error_count).to eq(2)
      end

      it 'does not run update callbacks for backoff bookkeeping' do
        expect(channel).not_to receive(:create_audit_log_entry)

        expect { channel.imap_fetch_error! }.not_to(change { channel.reload.updated_at })
      end

      it 'caps the pause at 60 minutes from the fifth failure onwards' do
        7.times { channel.imap_fetch_error! }

        expect(channel.reload.imap_fetch_error_count).to eq(7)
        expect(channel.imap_fetch_paused_till).to be_within(10.seconds).of(60.minutes.from_now)
      end
    end

    describe '#clear_imap_fetch_backoff!' do
      it 'resets the error count and pause' do
        5.times { channel.imap_fetch_error! }

        channel.clear_imap_fetch_backoff!

        expect(channel.reload.imap_fetch_error_count).to eq(0)
        expect(channel.imap_fetch_paused_till).to be_nil
      end
    end

    describe 'reset on imap settings change' do
      before { 5.times { channel.imap_fetch_error! } }

      it 'resets backoff when imap settings are updated' do
        channel.update!(imap_address: 'imap.example.com')

        expect(channel.reload.imap_fetch_error_count).to eq(0)
        expect(channel.imap_fetch_paused_till).to be_nil
      end

      it 'resets backoff when provider_config is updated' do
        channel.update!(provider_config: { access_token: 'new-token' })

        expect(channel.reload.imap_fetch_error_count).to eq(0)
        expect(channel.imap_fetch_paused_till).to be_nil
      end

      it 'does not reset backoff when unrelated attributes are updated' do
        channel.update!(smtp_address: 'smtp.example.com')

        expect(channel.reload.imap_fetch_error_count).to eq(5)
        expect(channel.imap_fetch_paused_till).to be_present
      end
    end
  end

  context 'when google?' do
    it 'returns false' do
      expect(channel.google?).to be(false)
    end

    it 'returns true' do
      channel.provider = 'google'
      expect(channel.google?).to be(true)
    end
  end
end
