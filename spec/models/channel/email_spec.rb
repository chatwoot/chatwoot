# frozen_string_literal: true

# == Schema Information
#
# Table name: channel_email
#
#  id                        :bigint           not null, primary key
#  email                     :string           not null
#  forward_to_email          :string           not null
#  imap_address              :string           default("")
#  imap_enable_ssl           :boolean          default(TRUE)
#  imap_enabled              :boolean          default(FALSE)
#  imap_login                :string           default("")
#  imap_password             :string           default("")
#  imap_port                 :integer          default(0)
#  provider                  :string
#  provider_config           :jsonb
#  smtp_address              :string           default("")
#  smtp_authentication       :string           default("login")
#  smtp_domain               :string           default("")
#  smtp_enable_ssl_tls       :boolean          default(FALSE)
#  smtp_enable_starttls_auto :boolean          default(TRUE)
#  smtp_enabled              :boolean          default(FALSE)
#  smtp_login                :string           default("")
#  smtp_openssl_verify_mode  :string           default("none")
#  smtp_password             :string           default("")
#  smtp_port                 :integer          default(0)
#  verified_for_sending      :boolean          default(FALSE), not null
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  account_id                :integer          not null
#
# Indexes
#
#  index_channel_email_on_email             (email) UNIQUE
#  index_channel_email_on_forward_to_email  (forward_to_email) UNIQUE
#
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
