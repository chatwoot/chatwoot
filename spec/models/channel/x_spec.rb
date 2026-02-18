# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join 'spec/models/concerns/reauthorizable_shared.rb'

RSpec.describe Channel::X do
  let(:channel) { create(:channel_x) }

  it { is_expected.to validate_presence_of(:account_id) }
  it { is_expected.to validate_presence_of(:profile_id) }
  it { is_expected.to validate_presence_of(:username) }
  it { is_expected.to belong_to(:account) }
  it { is_expected.to have_one(:inbox).dependent(:destroy_async) }

  it 'has a valid name' do
    expect(channel.name).to eq('X')
  end

  describe '#token_expired?' do
    context 'when token_expires_at is blank' do
      it 'returns true' do
        channel.token_expires_at = nil
        expect(channel.token_expired?).to be true
      end
    end

    context 'when token is expired' do
      it 'returns true' do
        channel.token_expires_at = 1.hour.ago
        expect(channel.token_expired?).to be true
      end
    end

    context 'when token is not expired' do
      it 'returns false' do
        channel.token_expires_at = 1.hour.from_now
        expect(channel.token_expired?).to be false
      end
    end
  end

  describe '#refresh_token_valid?' do
    context 'when refresh_token_expires_at is blank' do
      it 'returns false' do
        channel.refresh_token_expires_at = nil
        expect(channel.refresh_token_valid?).to be false
      end
    end

    context 'when refresh token is expired' do
      it 'returns false' do
        channel.refresh_token_expires_at = 1.day.ago
        expect(channel.refresh_token_valid?).to be false
      end
    end

    context 'when refresh token is valid' do
      it 'returns true' do
        channel.refresh_token_expires_at = 1.month.from_now
        expect(channel.refresh_token_valid?).to be true
      end
    end
  end

  describe '#client' do
    it 'returns an X::Client instance' do
      expect(channel.client).to be_a(X::Client)
    end

    it 'memoizes the client' do
      client1 = channel.client
      client2 = channel.client
      expect(client1.object_id).to eq(client2.object_id)
    end
  end

  describe 'concerns' do
    it_behaves_like 'reauthorizable'

    context 'when prompt_reauthorization!' do
      it 'calls channel notifier mail for X' do
        admin_mailer = double
        mailer_double = double

        expect(AdministratorNotifications::ChannelNotificationsMailer).to receive(:with).and_return(admin_mailer)
        expect(admin_mailer).to receive(:x_disconnect).with(channel.inbox).and_return(mailer_double)
        expect(mailer_double).to receive(:deliver_later)

        channel.prompt_reauthorization!
      end
    end
  end
end
