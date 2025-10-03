require 'rails_helper'

RSpec.describe Captain::CustomTool, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:account) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:endpoint_url) }
    it { is_expected.to define_enum_for(:http_method).with_values('GET' => 'GET', 'POST' => 'POST').backed_by_column_of_type(:string) }

    it {
      expect(subject).to define_enum_for(:auth_type).with_values('none' => 'none', 'bearer' => 'bearer', 'basic' => 'basic',
                                                                 'api_key' => 'api_key').backed_by_column_of_type(:string).with_prefix(:auth)
    }

    describe 'slug uniqueness' do
      let(:account) { create(:account) }

      it 'validates uniqueness of slug scoped to account' do
        create(:captain_custom_tool, account: account, slug: 'custom_test-tool')
        duplicate = build(:captain_custom_tool, account: account, slug: 'custom_test-tool')

        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:slug]).to include('has already been taken')
      end

      it 'allows same slug across different accounts' do
        account2 = create(:account)
        create(:captain_custom_tool, account: account, slug: 'custom_test-tool')
        different_account_tool = build(:captain_custom_tool, account: account2, slug: 'custom_test-tool')

        expect(different_account_tool).to be_valid
      end
    end
  end

  describe 'scopes' do
    let(:account) { create(:account) }

    describe '.enabled' do
      it 'returns only enabled custom tools' do
        enabled_tool = create(:captain_custom_tool, account: account, enabled: true)
        disabled_tool = create(:captain_custom_tool, account: account, enabled: false)

        expect(described_class.enabled).to include(enabled_tool)
        expect(described_class.enabled).not_to include(disabled_tool)
      end
    end
  end

  describe 'slug generation' do
    let(:account) { create(:account) }

    it 'generates slug from title on creation' do
      tool = create(:captain_custom_tool, account: account, title: 'Fetch Order Status')

      expect(tool.slug).to eq('custom_fetch-order-status')
    end

    it 'adds custom_ prefix to generated slug' do
      tool = create(:captain_custom_tool, account: account, title: 'My Tool')

      expect(tool.slug).to start_with('custom_')
    end

    it 'does not override manually set slug' do
      tool = create(:captain_custom_tool, account: account, title: 'Test Tool', slug: 'custom_manual-slug')

      expect(tool.slug).to eq('custom_manual-slug')
    end

    it 'handles slug collisions by appending counter' do
      create(:captain_custom_tool, account: account, title: 'Test Tool', slug: 'custom_test-tool')
      tool2 = create(:captain_custom_tool, account: account, title: 'Test Tool')

      expect(tool2.slug).to eq('custom_test-tool-1')
    end

    it 'handles multiple slug collisions' do
      create(:captain_custom_tool, account: account, title: 'Test Tool', slug: 'custom_test-tool')
      create(:captain_custom_tool, account: account, title: 'Test Tool', slug: 'custom_test-tool-1')
      tool3 = create(:captain_custom_tool, account: account, title: 'Test Tool')

      expect(tool3.slug).to eq('custom_test-tool-2')
    end

    it 'generates slug with UUID when title is blank' do
      tool = build(:captain_custom_tool, account: account, title: nil)
      tool.valid?

      expect(tool.slug).to match(/^custom_[0-9a-f-]+$/)
    end

    it 'parameterizes title correctly' do
      tool = create(:captain_custom_tool, account: account, title: 'Fetch Order Status & Details!')

      expect(tool.slug).to eq('custom_fetch-order-status-details')
    end
  end

  describe 'factory' do
    it 'creates a valid custom tool with default attributes' do
      tool = create(:captain_custom_tool)

      expect(tool).to be_valid
      expect(tool.title).to be_present
      expect(tool.slug).to be_present
      expect(tool.endpoint_url).to be_present
      expect(tool.http_method).to eq('GET')
      expect(tool.auth_type).to eq('none')
      expect(tool.enabled).to be true
    end

    it 'creates valid tool with POST trait' do
      tool = create(:captain_custom_tool, :with_post)

      expect(tool.http_method).to eq('POST')
      expect(tool.request_template).to be_present
    end

    it 'creates valid tool with bearer auth trait' do
      tool = create(:captain_custom_tool, :with_bearer_auth)

      expect(tool.auth_type).to eq('bearer')
      expect(tool.auth_config['token']).to eq('test_bearer_token_123')
    end

    it 'creates valid tool with basic auth trait' do
      tool = create(:captain_custom_tool, :with_basic_auth)

      expect(tool.auth_type).to eq('basic')
      expect(tool.auth_config['username']).to eq('test_user')
      expect(tool.auth_config['password']).to eq('test_pass')
    end

    it 'creates valid tool with api key trait' do
      tool = create(:captain_custom_tool, :with_api_key)

      expect(tool.auth_type).to eq('api_key')
      expect(tool.auth_config['key']).to eq('test_api_key')
      expect(tool.auth_config['location']).to eq('header')
    end
  end
end
