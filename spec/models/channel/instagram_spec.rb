# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join 'spec/models/concerns/reauthorizable_shared.rb'

RSpec.describe Channel::Instagram do
  let(:channel) { create(:channel_instagram) }

  it { is_expected.to validate_presence_of(:account_id) }
  it { is_expected.to validate_presence_of(:access_token) }
  it { is_expected.to validate_presence_of(:instagram_id) }
  it { is_expected.to belong_to(:account) }
  it { is_expected.to have_one(:inbox).dependent(:destroy_async) }

  it 'has a valid name' do
    expect(channel.name).to eq('Instagram')
  end

  describe '#create_contact_inbox_with_identifier' do
    let(:inbox) { channel.inbox }

    it 'creates contact inbox with identifier' do
      instagram_id = 'ig_12345'
      name = 'John Doe'
      identifier = 'john_doe_instagram'

      contact_inbox = channel.create_contact_inbox_with_identifier(instagram_id, name, identifier)

      expect(contact_inbox.contact.name).to eq(name)
      expect(contact_inbox.contact.identifier).to eq(identifier)
      expect(contact_inbox.source_id).to eq(instagram_id)
      expect(contact_inbox.inbox).to eq(inbox)
    end

    it 'creates contact inbox with fallback identifier when username is blank' do
      instagram_id = 'ig_12345'
      name = 'John Doe'
      identifier = 'ig_user_ig_12345'

      contact_inbox = channel.create_contact_inbox_with_identifier(instagram_id, name, identifier)

      expect(contact_inbox.contact.name).to eq(name)
      expect(contact_inbox.contact.identifier).to eq(identifier)
      expect(contact_inbox.source_id).to eq(instagram_id)
    end
  end

  describe 'concerns' do
    it_behaves_like 'reauthorizable'

    context 'when prompt_reauthorization!' do
      it 'calls channel notifier mail for instagram' do
        admin_mailer = double
        mailer_double = double

        expect(AdministratorNotifications::ChannelNotificationsMailer).to receive(:with).and_return(admin_mailer)
        expect(admin_mailer).to receive(:instagram_disconnect).with(channel.inbox).and_return(mailer_double)
        expect(mailer_double).to receive(:deliver_later)

        channel.prompt_reauthorization!
      end
    end
  end
end
