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
end
