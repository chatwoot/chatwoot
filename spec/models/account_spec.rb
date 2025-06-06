# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Account do
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_numericality_of(:auto_resolve_duration).is_greater_than_or_equal_to(1) }
  it { is_expected.to validate_numericality_of(:auto_resolve_duration).is_less_than_or_equal_to(999) }

  it { is_expected.to have_many(:users).through(:account_users) }
  it { is_expected.to have_many(:account_users) }
  it { is_expected.to have_many(:inboxes).dependent(:destroy_async) }
  it { is_expected.to have_many(:conversations).dependent(:destroy_async) }
  it { is_expected.to have_many(:contacts).dependent(:destroy_async) }
  it { is_expected.to have_many(:telegram_bots).dependent(:destroy_async) }
  it { is_expected.to have_many(:canned_responses).dependent(:destroy_async) }
  it { is_expected.to have_many(:facebook_pages).class_name('::Channel::FacebookPage').dependent(:destroy_async) }
  it { is_expected.to have_many(:web_widgets).class_name('::Channel::WebWidget').dependent(:destroy_async) }
  it { is_expected.to have_many(:webhooks).dependent(:destroy_async) }
  it { is_expected.to have_many(:notification_settings).dependent(:destroy_async) }
  it { is_expected.to have_many(:reporting_events) }
  it { is_expected.to have_many(:portals).dependent(:destroy_async) }
  it { is_expected.to have_many(:categories).dependent(:destroy_async) }
  it { is_expected.to have_many(:teams).dependent(:destroy_async) }

  # This validation happens in ApplicationRecord
  describe 'length validations' do
    let(:account) { create(:account) }

    it 'validates name length' do
      account.name = 'a' * 256
      account.valid?
      expect(account.errors[:name]).to include('is too long (maximum is 255 characters)')
    end

    it 'validates domain length' do
      account.domain = 'a' * 150
      account.valid?
      expect(account.errors[:domain]).to include('is too long (maximum is 100 characters)')
    end
  end

  describe 'usage_limits' do
    let(:account) { create(:account) }

    it 'returns ChatwootApp.max limits' do
      expect(account.usage_limits[:agents]).to eq(ChatwootApp.max_limit)
      expect(account.usage_limits[:inboxes]).to eq(ChatwootApp.max_limit)
    end
  end

  context 'when after_destroy is called' do
    it 'conv_dpid_seq and camp_dpid_seq_ are deleted' do
      account = create(:account)
      query = "select * from information_schema.sequences where sequence_name in  ('camp_dpid_seq_#{account.id}', 'conv_dpid_seq_#{account.id}');"
      expect(ActiveRecord::Base.connection.execute(query).count).to eq(2)
      expect(account.locale).to eq('en')
      account.destroy
      expect(ActiveRecord::Base.connection.execute(query).count).to eq(0)
    end
  end

  describe 'locale' do
    it 'returns correct language if the value is set' do
      account = create(:account, locale: 'fr')
      expect(account.locale).to eq('fr')
      expect(account.locale_english_name).to eq('french')
    end

    it 'returns english if the value is not set' do
      account = create(:account, locale: nil)
      expect(account.locale).to be_nil
      expect(account.locale_english_name).to eq('english')
    end

    it 'returns english if the value is empty string' do
      account = create(:account, locale: '')
      expect(account.locale).to be_nil
      expect(account.locale_english_name).to eq('english')
    end

    it 'returns correct language if the value has country code' do
      account = create(:account, locale: 'pt_BR')
      expect(account.locale).to eq('pt_BR')
      expect(account.locale_english_name).to eq('portuguese')
    end
  end
end
