require 'rails_helper'

RSpec.describe CustomFilter do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:user) { create(:user, account: account) }
  let(:store) { Conversations::UnreadCounts::FilteredCountStore }

  after do
    Current.user = nil
    Current.account = nil
  end

  describe 'filtered unread count invalidation' do
    before do
      account.enable_features!(:unread_count_for_filters)
    end

    it 'invalidates the folder index and filter version when a conversation filter is created' do
      custom_filter = nil

      expect do
        custom_filter = create(:custom_filter, account: account, user: user, filter_type: :conversation)
      end.to change { store.folder_index_version(account_id: account.id, user_id: user.id) }.by(1)
      expect(store.filter_version(account_id: account.id, filter_id: custom_filter.id)).to eq(1)
    end

    it 'invalidates only the filter version when the query changes' do
      custom_filter = create(:custom_filter, account: account, user: user, filter_type: :conversation)
      folder_index_version = store.folder_index_version(account_id: account.id, user_id: user.id)

      expect do
        custom_filter.update!(query: { payload: [{ attribute_key: 'status', values: ['resolved'] }] })
      end.to(change { store.filter_version(account_id: account.id, filter_id: custom_filter.id) }.by(1))
      expect(store.folder_index_version(account_id: account.id, user_id: user.id)).to eq(folder_index_version)
    end

    it 'does not invalidate counts when only the name changes' do
      custom_filter = create(:custom_filter, account: account, user: user, filter_type: :conversation)

      expect do
        custom_filter.update!(name: 'Renamed filter')
      end.not_to(change { store.filter_version(account_id: account.id, filter_id: custom_filter.id) })
    end

    it 'invalidates the folder index and deletes the count when a conversation filter is destroyed' do
      custom_filter = create(:custom_filter, account: account, user: user, filter_type: :conversation)
      store.write_filter_count!(
        account_id: account.id,
        filter_id: custom_filter.id,
        user_id: user.id,
        count: 3,
        account_version: 0,
        filter_version: 0,
        owner_built_in_filter_version: 0
      )

      expect do
        custom_filter.destroy!
      end.to change { store.folder_index_version(account_id: account.id, user_id: user.id) }.by(1)
      expect(store.filter_count(account_id: account.id, filter_id: custom_filter.id)).to be_nil
    end
  end

  describe '#set_visibility' do
    let(:custom_filter) { create(:custom_filter, account: account, user: admin) }

    context 'when user is administrator' do
      it 'sets visibility from params' do
        Current.account = account

        expect(custom_filter.visibility).to eq('personal')

        custom_filter.set_visibility(admin, { visibility: :global })
        expect(custom_filter.visibility).to eq('global')

        custom_filter.set_visibility(admin, { visibility: :personal })
        expect(custom_filter.visibility).to eq('personal')
      end
    end

    context 'when user is agent' do
      it 'forces visibility to personal regardless of params' do
        Current.account = account

        custom_filter.set_visibility(agent, { visibility: :global })
        expect(custom_filter.visibility).to eq('personal')
      end
    end

    context 'when params do not include visibility' do
      it 'keeps existing visibility for administrators' do
        Current.account = account
        custom_filter.update!(visibility: :global)

        custom_filter.set_visibility(admin, {})
        expect(custom_filter.visibility).to eq('global')
      end
    end
  end

  describe '.with_visibility' do
    let(:agent_two) { create(:user, account: account, role: :agent) }

    before do
      Current.account = account
      create(:custom_filter, account: account, user: admin, filter_type: 0, visibility: :global, name: 'admin global')
      create(:custom_filter, account: account, user: admin, filter_type: 0, visibility: :personal, name: 'admin personal')
      create(:custom_filter, account: account, user: agent, filter_type: 0, visibility: :personal, name: 'agent personal')
      create(:custom_filter, account: account, user: agent_two, filter_type: 0, visibility: :personal, name: 'agent_two personal')
      create(:custom_filter, account: account, user: admin, filter_type: 1, visibility: :global, name: 'admin contact global')
    end

    it 'returns globals plus the requesting user personal filters scoped by filter_type' do
      filters = described_class.with_visibility(agent, { filter_type: 'conversation' })
      names = filters.pluck(:name)

      expect(names).to include('admin global', 'agent personal')
      expect(names).not_to include('admin personal', 'agent_two personal', 'admin contact global')
    end

    it 'defaults to conversation when filter_type is missing' do
      filters = described_class.with_visibility(admin, {})

      expect(filters.pluck(:filter_type).uniq).to eq(['conversation'])
    end

    it 'defaults to conversation when filter_type is invalid' do
      filters = described_class.with_visibility(admin, { filter_type: 'bogus' })

      expect(filters.pluck(:filter_type).uniq).to eq(['conversation'])
    end

    it 'isolates by filter_type for contacts' do
      filters = described_class.with_visibility(agent, { filter_type: 'contact' })

      expect(filters.pluck(:name)).to eq(['admin contact global'])
    end
  end

  describe 'before the visibility column exists' do
    # Instances updated from before v4.13.0-fazer-ai.67 run migrations that load this model
    # while custom_filters has no visibility column yet (it only arrives in 20260510160215).
    let(:connection) { described_class.connection }

    before do
      connection.remove_column :custom_filters, :visibility
      described_class.reset_column_information
    end

    after { described_class.reset_column_information }

    it 'lets the country_code cleanup migration run' do
      filter = create(:custom_filter, account: account, user: user, filter_type: :conversation,
                                      query: { 'payload' => [{ 'attribute_key' => 'country_code' }, { 'attribute_key' => 'status' }] })
      require Rails.root.join('db/migrate/20260112092041_remove_country_code_from_conversation_filters.rb')

      ActiveRecord::Migration.suppress_messages { RemoveCountryCodeFromConversationFilters.new.migrate(:up) }

      expect(filter.reload.query['payload']).to eq([{ 'attribute_key' => 'status' }])
    end
  end
end
