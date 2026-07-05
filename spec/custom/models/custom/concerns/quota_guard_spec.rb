require 'rails_helper'

RSpec.describe Custom::Concerns::QuotaGuard do
  let(:account) { create(:account) }

  # second_attrs shape the second record so it does not trip unrelated
  # uniqueness validations (e.g. webhook url).
  shared_examples 'a quota guarded model' do |factory, resource, second_attrs = {}|
    it "denies #{factory} creation at the cap" do
      account.update!(limits: { resource => 1 })
      create(factory, account: account)
      record = build(factory, account: account, **second_attrs)

      expect(record).not_to be_valid
      expect(record.errors[:base].first).to include('Account limit exceeded')
    end

    it "allows #{factory} creation below the cap" do
      account.update!(limits: { resource => 2 })
      create(factory, account: account)

      expect(build(factory, account: account, **second_attrs)).to be_valid
    end

    it "leaves #{factory} updates unrestricted at the cap" do
      account.update!(limits: { resource => 1 })
      record = create(factory, account: account)

      expect(record).to be_valid
    end
  end

  it_behaves_like 'a quota guarded model', :team, :teams
  it_behaves_like 'a quota guarded model', :inbox, :inboxes
  it_behaves_like 'a quota guarded model', :webhook, :webhooks, { url: 'https://example.com/second' }
  it_behaves_like 'a quota guarded model', :label, :labels
  it_behaves_like 'a quota guarded model', :agent_bot, :agent_bots
  it_behaves_like 'a quota guarded model', :custom_attribute_definition, :custom_attribute_definitions
  it_behaves_like 'a quota guarded model', :automation_rule, :automation_rules

  describe 'integrations quota on Integrations::Hook' do
    it 'denies hook creation at the cap' do
      account.update!(limits: { integrations: 1 })
      create(:integrations_hook, account: account)
      record = build(:integrations_hook, :dialogflow, account: account, inbox: create(:inbox, account: account))

      expect(record).not_to be_valid
      expect(record.errors[:base].first).to include('Account limit exceeded')
    end

    it 'allows hook creation below the cap' do
      account.update!(limits: { integrations: 2 })
      create(:integrations_hook, account: account)

      expect(build(:integrations_hook, :dialogflow, account: account, inbox: create(:inbox, account: account))).to be_valid
    end
  end

  describe 'agents quota on AccountUser' do
    it 'denies adding a user beyond the cap (covers the platform API bypass)' do
      account.update!(limits: { agents: 1 })
      create(:account_user, account: account, user: create(:user))
      record = build(:account_user, account: account, user: create(:user))

      expect(record).not_to be_valid
      expect(record.errors[:base].first).to include('Account limit exceeded')
    end

    it 'allows adding a user below the cap' do
      account.update!(limits: { agents: 2 })
      create(:account_user, account: account, user: create(:user))

      expect(build(:account_user, account: account, user: create(:user))).to be_valid
    end
  end

  describe 'account-less records' do
    it 'skips the guard for system agent bots' do
      expect(build(:agent_bot, account: nil)).to be_valid
    end
  end

  describe 'platform-managed records bypass the guard (ADR-0005)' do
    it 'allows a platform-managed agent bot at the cap' do
      account.update!(limits: { agent_bots: 1 })
      create(:agent_bot, account: account)

      expect(build(:agent_bot, account: account, platform_managed: true)).to be_valid
    end

    it 'allows a platform-managed webhook at the cap' do
      account.update!(limits: { webhooks: 1 })
      create(:webhook, account: account)

      expect(build(:webhook, account: account, url: 'https://example.com/platform', platform_managed: true)).to be_valid
    end

    it 'allows a platform-managed account user at the cap' do
      account.update!(limits: { agents: 1 })
      create(:account_user, account: account, user: create(:user))

      expect(build(:account_user, account: account, user: create(:user), platform_managed: true)).to be_valid
    end
  end
end
