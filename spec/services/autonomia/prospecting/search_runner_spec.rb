require 'rails_helper'

RSpec.describe Autonomia::Prospecting::SearchRunner do
  let(:account) { create(:account) }
  let(:user) { create(:user, :administrator, account: account) }

  it 'creates a completed search and persists mock leads' do
    result = described_class.new(
      account: account,
      user: user,
      params: { query: 'clinica odontologica', location: 'Curitiba, PR', requested_limit: 3 }
    ).perform

    expect(result.search).to be_completed
    expect(result.search.query).to eq('clinica odontologica')
    expect(result.leads.size).to eq(3)
    expect(account.autonomia_prospecting_leads.count).to eq(3)
    expect(result.search.metadata['lead_ids']).to match_array(result.leads.map(&:id))
  end

  it 'deduplicates leads inside the same account' do
    params = { query: 'restaurante', location: 'Sao Paulo, SP', requested_limit: 2 }

    described_class.new(account: account, user: user, params: params).perform
    second_result = described_class.new(account: account, user: user, params: params).perform

    expect(second_result.leads.size).to eq(2)
    expect(account.autonomia_prospecting_leads.count).to eq(2)
    expect(second_result.search.metadata['lead_ids']).to match_array(second_result.leads.map(&:id))
  end

  it 'keeps dedupe scoped to account' do
    params = { query: 'academia', location: 'Rio de Janeiro, RJ', requested_limit: 1 }
    other_account = create(:account)
    other_user = create(:user, :administrator, account: other_account)

    described_class.new(account: account, user: user, params: params).perform
    described_class.new(account: other_account, user: other_user, params: params).perform

    expect(account.autonomia_prospecting_leads.count).to eq(1)
    expect(other_account.autonomia_prospecting_leads.count).to eq(1)
  end

  it 'rejects limits over account settings' do
    Autonomia::Prospecting::Setting.for_account(account).update!(max_results_per_search: 2)

    expect do
      described_class.new(
        account: account,
        user: user,
        params: { query: 'hotel', location: 'Sao Paulo, SP', requested_limit: 3 }
      ).perform
    end.to raise_error(ActiveRecord::RecordInvalid, /less than or equal to 2/)
  end

  it 'rejects google places when account key is missing' do
    Autonomia::Prospecting::Setting.for_account(account).update!(
      provider: 'google_places',
      provider_enabled: true
    )

    expect do
      described_class.new(
        account: account,
        user: user,
        params: { query: 'hotel', location: 'Sao Paulo, SP', requested_limit: 1, provider: 'google_places' }
      ).perform
    end.to raise_error(Autonomia::Prospecting::SearchRunner::ProviderError, /API key/)
  end

  it 'uses cache for repeated searches with the same fingerprint' do
    Autonomia::Prospecting::Setting.for_account(account).update!(cache_ttl_seconds: 3600)
    params = { query: 'padaria', location: 'Sao Paulo, SP', requested_limit: 1 }

    first = described_class.new(account: account, user: user, params: params).perform
    second = described_class.new(account: account, user: user, params: params).perform

    expect(first.search).to be_completed
    expect(second.search).to be_cached
    expect(second.leads.map(&:id)).to eq(first.leads.map(&:id))
    expect(second.search.consumed_api_units).to eq(0)
  end
end
