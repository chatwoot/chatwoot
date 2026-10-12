require 'rails_helper'

RSpec.describe WhatsappInteractivePresetPolicy do
  let(:account) { create(:account) }
  let(:creator) { create(:user, account: account, role: :agent) }
  let(:other_agent) { create(:user, account: account, role: :agent) }
  let(:administrator) { create(:user, account: account, role: :administrator) }
  let(:preset) { create(:whatsapp_interactive_preset, account: account, created_by: creator) }

  def policy_for(user)
    account_user = account.account_users.find_by!(user: user)
    described_class.new({ user: user, account: account, account_user: account_user }, preset)
  end

  it 'allows account members to read and create presets' do
    policy = policy_for(other_agent)

    expect(policy).to be_index
    expect(policy).to be_show
    expect(policy).to be_create
  end

  it 'allows only the active creator to update an original' do
    expect(policy_for(creator)).to be_update
    expect(policy_for(other_agent)).not_to be_update
    expect(policy_for(administrator)).not_to be_update

    account.account_users.find_by!(user: creator).destroy!
    expect(policy_for(other_agent)).not_to be_update
  end

  it 'allows only administrators to delete' do
    expect(policy_for(administrator)).to be_destroy
    expect(policy_for(creator)).not_to be_destroy
    expect(policy_for(other_agent)).not_to be_destroy
  end
end
