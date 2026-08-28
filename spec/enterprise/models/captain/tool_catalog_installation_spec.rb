require 'rails_helper'

RSpec.describe Captain::ToolCatalogInstallation, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:initiated_by).class_name('User') }
    it { is_expected.to belong_to(:integration_hook).class_name('Integrations::Hook').optional }
  end

  describe 'validations' do
    it 'accepts a pending installation with versioned template selections' do
      expect(build(:captain_tool_catalog_installation)).to be_valid
    end

    it {
      expect(subject).to define_enum_for(:workflow_kind).with_values(
        'install' => 'install',
        'update' => 'update',
        'reconnect' => 'reconnect',
        'connect' => 'connect'
      ).backed_by_column_of_type(:string).with_prefix(:workflow)
    }

    it 'requires at least one selected template' do
      installation = build(:captain_tool_catalog_installation, selected_templates: [])

      expect(installation).not_to be_valid
      expect(installation.errors[:selected_templates]).to include('must be a non-empty array')
    end

    it 'allows an update to remove every selected tool' do
      installation = build(
        :captain_tool_catalog_installation,
        workflow_kind: 'update',
        selected_templates: [],
        status: 'completed',
        resulting_tool_ids: [],
        completed_at: Time.current
      )

      expect(installation).to be_valid
    end

    it 'rejects unversioned or non-object template configuration' do
      installation = build(
        :captain_tool_catalog_installation,
        selected_templates: [{ 'template_key' => 'find_customer', 'template_version' => 'latest', 'configuration' => [] }]
      )

      expect(installation).not_to be_valid
      expect(installation.errors[:selected_templates]).to include('must contain template keys, versions, and object configuration only')
    end

    it 'stores only a SHA-256 OAuth nonce digest' do
      installation = build(:captain_tool_catalog_installation, oauth_nonce_digest: 'raw-oauth-state')

      expect(installation).not_to be_valid
      expect(installation.errors[:oauth_nonce_digest]).to be_present
    end

    it 'requires completed installations to record results and completion time' do
      installation = build(:captain_tool_catalog_installation, status: 'completed', resulting_tool_ids: [], completed_at: nil)

      expect(installation).not_to be_valid
      expect(installation.errors).to include(:resulting_tool_ids, :completed_at)
    end

    it 'rejects provider error payloads in error_code' do
      installation = build(:captain_tool_catalog_installation, error_code: 'Provider said: token=secret')

      expect(installation).not_to be_valid
      expect(installation.errors[:error_code]).to be_present
    end

    it 'rejects a connection owned by another account' do
      installation = build(:captain_tool_catalog_installation, integration_hook: create(:integrations_hook))

      expect(installation).not_to be_valid
      expect(installation.errors[:integration_hook]).to include('must belong to the same account')
    end

    it 'rejects resulting tools owned by another account' do
      tool = create(:captain_custom_tool)
      installation = build(:captain_tool_catalog_installation, account: create(:account), resulting_tool_ids: [tool.id])

      expect(installation).not_to be_valid
      expect(installation.errors[:resulting_tool_ids]).to include('must reference tools from the same account')
    end
  end

  describe '.active' do
    it 'returns only non-terminal installation sessions' do
      pending = create(:captain_tool_catalog_installation)
      failed = create(:captain_tool_catalog_installation, status: 'failed', error_code: 'connection_failed')

      expect(described_class.active).to contain_exactly(pending)
      expect(described_class.active).not_to include(failed)
    end
  end

  describe '#expire_if_needed!' do
    it 'expires an active session after its deadline' do
      installation = create(:captain_tool_catalog_installation, status: 'awaiting_connection', expires_at: 1.minute.ago)

      installation.expire_if_needed!

      expect(installation).to be_expired
    end

    it 'does not rewrite a completed session' do
      tool = create(:captain_custom_tool)
      installation = create(
        :captain_tool_catalog_installation,
        status: 'completed',
        account: tool.account,
        resulting_tool_ids: [tool.id],
        completed_at: 1.hour.ago,
        expires_at: 1.minute.ago
      )

      expect { installation.expire_if_needed! }.not_to(change { installation.reload.status })
    end
  end
end
