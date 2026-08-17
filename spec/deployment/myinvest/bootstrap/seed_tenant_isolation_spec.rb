require 'rails_helper'

RSpec.describe 'MyInvest bootstrap tenant isolation' do # rubocop:disable RSpec/DescribeClass
  let(:seed_path) { Rails.root.join('deployment/myinvest/bootstrap/seed.rb') }
  let(:environment) do
    {
      'ADMIN_NAME' => 'Bootstrap Admin',
      'ADMIN_EMAIL' => 'bootstrap@example.test',
      'ADMIN_PASSWORD' => 'Password1!',
      'MYINVEST_ACCOUNT_NAME' => 'MyInvest Pro',
      'ACADEMY_NEW_ACCOUNT_NAME' => 'Academy Neu',
      'ACADEMY_LEGACY_ACCOUNT_NAME' => 'Academy Alt',
      'MYINVEST_WEBSITE_URL' => 'https://app.example.test',
      'ACADEMY_NEW_WEBSITE_URL' => 'https://academy.example.test',
      'ACADEMY_LEGACY_WEBSITE_URL' => 'https://legacy.example.test',
      'FRONTEND_URL' => 'https://support.example.test'
    }
  end

  before do
    allow(FileUtils).to receive(:mkdir_p)
    allow(File).to receive(:write)
    allow(File).to receive(:rename)
    allow(File).to receive(:chmod)
    allow($stdout).to receive(:puts)
  end

  it 'rejects a duplicate canonical key before writing anything' do
    create(:account, name: 'MyInvest Pro', custom_attributes: { 'myinvest_tenant_key' => 'saas' })
    create(:account, name: 'Duplicate SaaS', custom_attributes: { 'myinvest_tenant_key' => 'saas' })
    counts_before = [Account.count, User.count, Inbox.count, AgentBot.count]

    expect do
      with_modified_env(environment) { load seed_path }
    end.to raise_error('Duplicate MyInvest tenant account for key: saas')

    expect([Account.count, User.count, Inbox.count, AgentBot.count]).to eq(counts_before)
  end

  it 'rejects an unkeyed display-name collision instead of adopting it' do
    existing = create(:account, name: 'MyInvest Pro')
    counts_before = [Account.count, User.count, Inbox.count, AgentBot.count]

    expect do
      with_modified_env(environment) { load seed_path }
    end.to raise_error('MyInvest tenant account name is already used without its canonical key: MyInvest Pro')

    expect(existing.reload.custom_attributes).not_to have_key('myinvest_tenant_key')
    expect([Account.count, User.count, Inbox.count, AgentBot.count]).to eq(counts_before)
  end

  it 'rejects noncanonical MyInvest tenant keys before writing anything' do
    create(:account, name: 'Unexpected', custom_attributes: { 'myinvest_tenant_key' => 'academy' })
    counts_before = [Account.count, User.count, Inbox.count, AgentBot.count]

    expect do
      with_modified_env(environment) { load seed_path }
    end.to raise_error('Unknown MyInvest tenant keys: academy')

    expect([Account.count, User.count, Inbox.count, AgentBot.count]).to eq(counts_before)
  end

  it 'is idempotent for three existing canonical accounts' do
    accounts = {
      'saas' => create(:account, name: 'MyInvest Pro', custom_attributes: { 'myinvest_tenant_key' => 'saas' }),
      'new_academy' => create(:account, name: 'Academy Neu', custom_attributes: { 'myinvest_tenant_key' => 'new_academy' }),
      'legacy_academy' => create(:account, name: 'Academy Alt', custom_attributes: { 'myinvest_tenant_key' => 'legacy_academy' })
    }

    with_modified_env(environment) { load seed_path }
    record_ids = {
      accounts: Account.where(id: accounts.values).order(:id).ids,
      inboxes: Inbox.order(:id).ids,
      agent_bots: AgentBot.order(:id).ids,
      inbox_members: InboxMember.order(:id).ids
    }

    expect { with_modified_env(environment) { load seed_path } }.not_to change(Account, :count)
    expect(Account.where("custom_attributes ->> 'myinvest_tenant_key' IN (?)", accounts.keys).distinct.count).to eq(3)
    expect(Inbox.order(:id).ids).to eq(record_ids[:inboxes])
    expect(AgentBot.order(:id).ids).to eq(record_ids[:agent_bots])
    expect(InboxMember.order(:id).ids).to eq(record_ids[:inbox_members])
    expect(Account.where(id: accounts.values).order(:id).ids).to eq(record_ids[:accounts])
  end
end
