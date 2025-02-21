# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join 'spec/models/concerns/out_of_offisable_shared.rb'
require Rails.root.join 'spec/models/concerns/avatarable_shared.rb'

RSpec.describe Inbox do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:account_id) }
    it { is_expected.to validate_presence_of(:name) }
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

  describe '#add_members' do
    let(:inbox) { FactoryBot.create(:inbox) }

    before do
      allow(Rails.configuration.dispatcher).to receive(:dispatch)
    end

    it 'handles adds all members and resets cache keys' do
      users = FactoryBot.create_list(:user, 3)
      inbox.add_members(users.map(&:id))
      expect(inbox.reload.inbox_members.size).to eq(3)

      expect(Rails.configuration.dispatcher).to have_received(:dispatch).at_least(:once)
                                                                        .with(
                                                                          'account.cache_invalidated',
                                                                          kind_of(Time),
                                                                          account: inbox.account,
                                                                          cache_keys: inbox.account.cache_keys
                                                                        )
    end
  end

  describe '#remove_members' do
    let(:inbox) { FactoryBot.create(:inbox) }
    let(:users) { FactoryBot.create_list(:user, 3) }

    before do
      inbox.add_members(users.map(&:id))
      allow(Rails.configuration.dispatcher).to receive(:dispatch)
    end

    it 'removes the members and resets cache keys' do
      expect(inbox.reload.inbox_members.size).to eq(3)

      inbox.remove_members(users.map(&:id))
      expect(inbox.reload.inbox_members.size).to eq(0)

      expect(Rails.configuration.dispatcher).to have_received(:dispatch).at_least(:once)
                                                                        .with(
                                                                          'account.cache_invalidated',
                                                                          kind_of(Time),
                                                                          account: inbox.account,
                                                                          cache_keys: inbox.account.cache_keys
                                                                        )
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
end
