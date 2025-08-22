# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join 'spec/models/concerns/out_of_offisable_shared.rb'
require Rails.root.join 'spec/models/concerns/avatarable_shared.rb'

RSpec.describe Inbox do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:account_id) }
    it { is_expected.to validate_presence_of(:name) }

    describe 'CSAT expiry validations' do
      it 'validates csat_expiry_hours is within valid range' do
        inbox = build(:inbox, csat_expiry_hours: 8761)
        expect(inbox).not_to be_valid
        expect(inbox.errors[:csat_expiry_hours]).to include('must be between 1 and 8760 hours (1 year)')
      end

      it 'validates csat_expiry_hours is greater than 0' do
        inbox = build(:inbox, csat_expiry_hours: 0)
        expect(inbox).not_to be_valid
        expect(inbox.errors[:csat_expiry_hours]).to include('must be between 1 and 8760 hours (1 year)')
      end

      it 'allows nil csat_expiry_hours' do
        inbox = build(:inbox, csat_expiry_hours: nil)
        expect(inbox).to be_valid
      end

      it 'requires csat_expiry_hours when resend after expiry is enabled' do
        inbox = build(:inbox, csat_allow_resend_after_expiry: true, csat_expiry_hours: nil)
        expect(inbox).not_to be_valid
        expect(inbox.errors[:csat_expiry_hours]).to include('must be specified when resend after expiry is enabled')
      end

      it 'prevents enabling resend when CSAT survey is disabled' do
        inbox = build(:inbox, csat_survey_enabled: false, csat_allow_resend_after_expiry: true)
        expect(inbox).not_to be_valid
        expect(inbox.errors[:csat_allow_resend_after_expiry]).to include('cannot be enabled when CSAT survey is disabled')
      end
    end
  end

  describe 'associations' do
    it { is_expected.to belong_to(:account) }

    it { is_expected.to belong_to(:channel) }

    it { is_expected.to have_many(:contact_inboxes).dependent(:destroy_async) }

    it { is_expected.to have_many(:contacts).through(:contact_inboxes) }

    it { is_expected.to have_many(:inbox_members).dependent(:destroy_async) }

    it { is_expected.to have_many(:members).through(:inbox_members).source(:user) }

    it { is_expected.to have_many(:conversations).dependent(:destroy_async) }

    it { is_expected.to have_many(:messages).dependent(:destroy_async) }

    it { is_expected.to have_one(:agent_bot_inbox) }

    it { is_expected.to have_many(:webhooks).dependent(:destroy_async) }

    it { is_expected.to have_many(:reporting_events) }

    it { is_expected.to have_many(:hooks) }
  end

  describe 'concerns' do
    it_behaves_like 'out_of_offisable'
    it_behaves_like 'avatarable'
  end

  describe '#add_member' do
    let(:inbox) { FactoryBot.create(:inbox) }
    let(:user) { FactoryBot.create(:user) }

    it do
      expect(inbox.inbox_members.size).to eq(0)

      inbox.add_member(user.id)
      expect(inbox.reload.inbox_members.size).to eq(1)
    end
  end

  describe '#remove_member' do
    let(:inbox) { FactoryBot.create(:inbox) }
    let(:user) { FactoryBot.create(:user) }

    before { inbox.add_member(user.id) }

    it do
      expect(inbox.inbox_members.size).to eq(1)

      inbox.remove_member(user.id)
      expect(inbox.reload.inbox_members.size).to eq(0)
    end
  end

  describe '#facebook?' do
    let(:inbox) do
      FactoryBot.build(:inbox, channel: channel_val)
    end

    context 'when the channel type is Channel::FacebookPage' do
      let(:channel_val) { Channel::FacebookPage.new }

      it do
        expect(inbox.facebook?).to be(true)
        expect(inbox.inbox_type).to eq('Facebook')
      end
    end

    context 'when the channel type is not Channel::FacebookPage' do
      let(:channel_val) { Channel::WebWidget.new }

      it do
        expect(inbox.facebook?).to be(false)
        expect(inbox.inbox_type).to eq('Website')
      end
    end
  end

  describe '#web_widget?' do
    let(:inbox) do
      FactoryBot.build(:inbox, channel: channel_val)
    end

    context 'when the channel type is Channel::WebWidget' do
      let(:channel_val) { Channel::WebWidget.new }

      it do
        expect(inbox.web_widget?).to be(true)
        expect(inbox.inbox_type).to eq('Website')
      end
    end

    context 'when the channel is not Channel::WebWidget' do
      let(:channel_val) { Channel::Api.new }

      it do
        expect(inbox.web_widget?).to be(false)
        expect(inbox.inbox_type).to eq('API')
      end
    end
  end

  describe '#api?' do
    let(:inbox) do
      FactoryBot.build(:inbox, channel: channel_val)
    end

    context 'when the channel type is Channel::Api' do
      let(:channel_val) { Channel::Api.new }

      it do
        expect(inbox.api?).to be(true)
        expect(inbox.inbox_type).to eq('API')
      end
    end

    context 'when the channel is not Channel::Api' do
      let(:channel_val) { Channel::FacebookPage.new }

      it do
        expect(inbox.api?).to be(false)
        expect(inbox.inbox_type).to eq('Facebook')
      end
    end
  end

  describe '#validations' do
    let(:inbox) { FactoryBot.create(:inbox) }

    context 'when validating inbox name' do
      it 'does not allow any special character at the end' do
        inbox.name = 'this is my inbox name-'
        expect(inbox).not_to be_valid
        expect(inbox.errors.full_messages).to eq(
          ['Name should not start or end with symbols, and it should not have < > / \\ @ characters.']
        )
      end

      it 'does not allow any special character at the start' do
        inbox.name = '-this is my inbox name'
        expect(inbox).not_to be_valid
        expect(inbox.errors.full_messages).to eq(
          ['Name should not start or end with symbols, and it should not have < > / \\ @ characters.']
        )
      end

      it 'does not allow chacters like /\@<> in the entire string' do
        inbox.name = 'inbox@name'
        expect(inbox).not_to be_valid
        expect(inbox.errors.full_messages).to eq(
          ['Name should not start or end with symbols, and it should not have < > / \\ @ characters.']
        )
      end

      it 'does not empty string' do
        inbox.name = ''
        expect(inbox).not_to be_valid
        expect(inbox.errors.full_messages[0]).to eq(
          "Name can't be blank"
        )
      end

      it 'does allow special characters except /\@<> in between' do
        inbox.name = 'inbox-name'
        expect(inbox).to be_valid

        inbox.name = 'inbox_name.and_1'
        expect(inbox).to be_valid
      end

      context 'when special characters allowed for some channel' do
        let!(:tw_channel_val) { FactoryBot.create(:channel_twitter_profile) }
        let(:inbox) { create(:inbox, channel: tw_channel_val) }

        it 'does allow special chacters like /\@<> for Facebook Channel' do
          inbox.name = 'inbox@name'
          expect(inbox).to be_valid
        end
      end
    end
  end

  describe '#update' do
    let!(:inbox) { FactoryBot.create(:inbox) }
    let!(:portal) { FactoryBot.create(:portal) }

    before do
      allow(Rails.configuration.dispatcher).to receive(:dispatch)
    end

    it 'set portal id in inbox' do
      inbox.portal_id = portal.id
      inbox.save

      expect(inbox.portal).to eq(portal)
    end

    it 'sends the inbox_created event if ENABLE_INBOX_EVENTS is true' do
      with_modified_env ENABLE_INBOX_EVENTS: 'true' do
        channel = inbox.channel
        channel.update(widget_color: '#fff')

        expect(Rails.configuration.dispatcher).to have_received(:dispatch)
          .with(
            'inbox.updated',
            kind_of(Time),
            inbox: inbox,
            changed_attributes: kind_of(Object)
          )
      end
    end

    it 'sends the inbox_created event if ENABLE_INBOX_EVENTS is false' do
      channel = inbox.channel
      channel.update(widget_color: '#fff')

      expect(Rails.configuration.dispatcher).not_to have_received(:dispatch)
        .with(
          'inbox.updated',
          kind_of(Time),
          inbox: inbox,
          changed_attributes: kind_of(Object)
        )
    end

    it 'resets cache key if there is an update in the channel' do
      channel = inbox.channel
      channel.update(widget_color: '#fff')

      expect(Rails.configuration.dispatcher).to have_received(:dispatch)
        .with(
          'account.cache_invalidated',
          kind_of(Time),
          account: inbox.account,
          cache_keys: inbox.account.cache_keys
        )
    end

    it 'updates the cache key after update' do
      expect(inbox.account).to receive(:update_cache_key).with('inbox')
      inbox.update(name: 'New Name')
    end

    it 'updates the cache key after touch' do
      expect(inbox.account).to receive(:update_cache_key).with('inbox')
      inbox.touch # rubocop:disable Rails/SkipsModelValidations
    end
  end

  describe 'CSAT expiry helper methods' do
    describe '#csat_expiry_enabled?' do
      it 'returns true when both conditions are met' do
        inbox = build(:inbox, csat_expiry_hours: 24, csat_allow_resend_after_expiry: true)
        expect(inbox.csat_expiry_enabled?).to be true
      end

      it 'returns false when expiry hours is nil' do
        inbox = build(:inbox, csat_expiry_hours: nil, csat_allow_resend_after_expiry: true)
        expect(inbox.csat_expiry_enabled?).to be false
      end

      it 'returns false when resend is disabled' do
        inbox = build(:inbox, csat_expiry_hours: 24, csat_allow_resend_after_expiry: false)
        expect(inbox.csat_expiry_enabled?).to be false
      end
    end

    describe '#csat_expires_after' do
      it 'returns configured hours when set' do
        inbox = build(:inbox, csat_expiry_hours: 48)
        expect(inbox.csat_expires_after).to eq(48.hours)
      end

      it 'returns default 336 hours (14 days) when not set' do
        inbox = build(:inbox, csat_expiry_hours: nil)
        expect(inbox.csat_expires_after).to eq(336.hours)
      end
    end
  end
end
