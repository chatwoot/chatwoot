require 'rails_helper'

RSpec.describe SuperAdmin::AccountFeaturesHelper do
  describe '.grouped_features' do
    let(:features) do
      {
        'companies' => true,
        'channel_email' => true,
        'audit_logs' => false,
        'macros' => true
      }
    end

    it 'groups features by category with labels and descriptions' do
      sections = described_class.grouped_features(features)
      keys = sections.pluck(:key)

      expect(keys).to include('channels', 'conversations', 'contacts', 'security')
      expect(keys).to eq(keys.sort_by { |k| described_class::CATEGORY_ORDER.index(k) })

      contacts = sections.find { |s| s[:key] == 'contacts' }
      companies = contacts[:items].find { |i| i[:key] == 'companies' }
      expect(companies[:premium]).to be(true)
      expect(companies[:enabled]).to be(true)
      expect(companies[:description]).to include('companies')
    end

    it 'excludes chatwoot_internal features on self-hosted' do
      allow(ChatwootApp).to receive(:chatwoot_cloud?).and_return(false)
      sections = described_class.grouped_features(features.merge('inbox_view' => true))
      all_keys = sections.flat_map { |s| s[:items].pluck(:key) }
      expect(all_keys).not_to include('inbox_view')
    end
  end
end
