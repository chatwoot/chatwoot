require 'rails_helper'

RSpec.describe Conversations::UnreadCounts::FilteredCountInvalidator do
  subject(:invalidator) { described_class.new(account) }

  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:other_user) { create(:user, account: account) }
  let(:filter_id) { 123 }
  let(:store) { Conversations::UnreadCounts::FilteredCountStore }

  after do
    redis_keys.each { |key| Redis::Alfred.delete(key) }
  end

  describe '#conversation_changed!' do
    it 'bumps the account conversation version when the feature is enabled' do
      account.enable_features!(:unread_count_for_filters)

      expect { invalidator.conversation_changed! }.to change { store.conversation_version(account.id) }.by(1)
    end

    it 'records invalidation instrumentation when the feature is enabled' do
      account.enable_features!(:unread_count_for_filters)
      allow(Conversations::UnreadCounts::FilteredCountInstrumentation).to receive(:increment)

      invalidator.conversation_changed!

      expect(Conversations::UnreadCounts::FilteredCountInstrumentation).to have_received(:increment).with(
        :invalidation,
        account_id: account.id,
        invalidation_scope: :conversation,
        reason: :conversation_changed,
        version: 1
      )
    end

    it 'does not write Redis keys when the feature is disabled' do
      expect { invalidator.conversation_changed! }.not_to(change { store.conversation_version(account.id) })
    end
  end

  describe '#user_visibility_changed!' do
    it 'bumps the user built-in filter version' do
      account.enable_features!(:unread_count_for_filters)

      expect do
        invalidator.user_visibility_changed!(user_id: user.id)
      end.to change { store.built_in_filter_version(account_id: account.id, user_id: user.id) }.by(1)
    end
  end

  describe '#users_visibility_changed!' do
    it 'pipelines built-in filter version bumps for multiple users' do
      account.enable_features!(:unread_count_for_filters)
      user_ids = [user.id, other_user.id]
      allow(Redis::Alfred).to receive(:pipelined).and_call_original

      expect do
        invalidator.users_visibility_changed!(user_ids: user_ids + [user.id, nil])
      end.to change { built_in_filter_version_for(user) }.by(1)
                                                         .and change { built_in_filter_version_for(other_user) }.by(1)

      expect(Redis::Alfred).to have_received(:pipelined).once
    end

    it 'does not write Redis keys when no user ids are present' do
      account.enable_features!(:unread_count_for_filters)

      expect(invalidator.users_visibility_changed!(user_ids: [nil, ''])).to be(false)
    end
  end

  describe '#custom_filter_created!' do
    it 'bumps the folder index and saved filter versions for conversation filters' do
      account.enable_features!(:unread_count_for_filters)
      filter_version = store.filter_version(account_id: account.id, filter_id: filter_id)

      expect do
        invalidator.custom_filter_created!(conversation_filter)
      end.to change { store.folder_index_version(account_id: account.id, user_id: user.id) }.by(1)
      expect(store.filter_version(account_id: account.id, filter_id: filter_id)).to eq(filter_version + 1)
    end

    it 'ignores non-conversation filters' do
      account.enable_features!(:unread_count_for_filters)

      expect do
        invalidator.custom_filter_created!(conversation_filter(is_conversation: false))
      end.not_to(change { store.folder_index_version(account_id: account.id, user_id: user.id) })
    end
  end

  describe '#custom_filter_updated!' do
    it 'bumps only the filter version when the query changes' do
      account.enable_features!(:unread_count_for_filters)
      filter = conversation_filter(previous_changes: { 'query' => [{ status: 'open' }, { status: 'resolved' }] })
      folder_index_version = store.folder_index_version(account_id: account.id, user_id: user.id)

      expect do
        invalidator.custom_filter_updated!(filter)
      end.to change { store.filter_version(account_id: account.id, filter_id: filter_id) }.by(1)
      expect(store.folder_index_version(account_id: account.id, user_id: user.id)).to eq(folder_index_version)
    end

    it 'ignores name-only updates' do
      account.enable_features!(:unread_count_for_filters)
      filter = conversation_filter(previous_changes: { 'name' => %w[Open Resolved] })

      expect do
        invalidator.custom_filter_updated!(filter)
      end.not_to(change { store.filter_version(account_id: account.id, filter_id: filter_id) })
    end

    it 'bumps versions and deletes the saved count when the filter moves away from conversations' do
      account.enable_features!(:unread_count_for_filters)
      filter = conversation_filter(
        is_conversation: false,
        previous_changes: { 'filter_type' => %w[conversation contact] }
      )
      store.write_filter_count!(
        account_id: account.id,
        filter_id: filter_id,
        user_id: user.id,
        count: 4,
        account_version: 0,
        filter_version: 0,
        owner_built_in_filter_version: 0
      )
      filter_version = store.filter_version(account_id: account.id, filter_id: filter_id)

      expect do
        invalidator.custom_filter_updated!(filter)
      end.to change { store.folder_index_version(account_id: account.id, user_id: user.id) }.by(1)
      expect(store.filter_version(account_id: account.id, filter_id: filter_id)).to eq(filter_version + 1)
      expect(store.filter_count(account_id: account.id, filter_id: filter_id)).to be_nil
    end
  end

  describe '#custom_filter_destroyed!' do
    it 'bumps the folder index version and deletes the saved count' do
      account.enable_features!(:unread_count_for_filters)
      store.write_filter_count!(
        account_id: account.id,
        filter_id: filter_id,
        user_id: user.id,
        count: 2,
        account_version: 0,
        filter_version: 0,
        owner_built_in_filter_version: 0
      )

      expect do
        invalidator.custom_filter_destroyed!(conversation_filter)
      end.to change { store.folder_index_version(account_id: account.id, user_id: user.id) }.by(1)
      expect(store.filter_count(account_id: account.id, filter_id: filter_id)).to be_nil
    end
  end

  describe '#custom_attribute_definition_changed!' do
    it 'bumps affected conversation saved filter versions' do
      account.enable_features!(:unread_count_for_filters)
      definition = create(:custom_attribute_definition, account: account, attribute_key: 'plan', attribute_model: 'conversation_attribute')
      matching_filter = create(:custom_filter, account: account, user: user, query: custom_attribute_query('plan'))
      blank_type_filter = create(:custom_filter, account: account, user: user, query: custom_attribute_query('plan', ''))
      contact_filter = create(:custom_filter, account: account, user: user, query: custom_attribute_query('plan', 'contact_attribute'))
      other_filter = create(:custom_filter, account: account, user: user, query: custom_attribute_query('tier'))
      versions = filter_versions(matching_filter, blank_type_filter, contact_filter, other_filter)

      invalidator.custom_attribute_definition_changed!(definition)

      expect(store.filter_version(account_id: account.id, filter_id: matching_filter.id)).to eq(versions[matching_filter.id] + 1)
      expect(store.filter_version(account_id: account.id, filter_id: blank_type_filter.id)).to eq(versions[blank_type_filter.id] + 1)
      expect(store.filter_version(account_id: account.id, filter_id: contact_filter.id)).to eq(versions[contact_filter.id])
      expect(store.filter_version(account_id: account.id, filter_id: other_filter.id)).to eq(versions[other_filter.id])
    end

    it 'bumps filters referencing the previous attribute key when the key changes' do
      definition = create(:custom_attribute_definition, account: account, attribute_key: 'plan', attribute_model: 'conversation_attribute')
      matching_filter = create(:custom_filter, account: account, user: user, query: custom_attribute_query('plan'))
      version = store.filter_version(account_id: account.id, filter_id: matching_filter.id)

      definition.update!(attribute_key: 'new_plan')
      account.enable_features!(:unread_count_for_filters)

      expect do
        invalidator.custom_attribute_definition_changed!(definition)
      end.to change { store.filter_version(account_id: account.id, filter_id: matching_filter.id) }.from(version).to(version + 1)
    end
  end

  def conversation_filter(is_conversation: true, previous_changes: {})
    instance_double(
      CustomFilter,
      id: filter_id,
      user_id: user.id,
      conversation?: is_conversation,
      previous_changes: previous_changes
    )
  end

  def custom_attribute_query(attribute_key, custom_attribute_type = 'conversation_attribute')
    {
      payload: [
        {
          attribute_key: attribute_key,
          filter_operator: 'equal_to',
          values: ['gold'],
          custom_attribute_type: custom_attribute_type
        }
      ]
    }
  end

  def filter_versions(*custom_filters)
    custom_filters.to_h { |custom_filter| [custom_filter.id, store.filter_version(account_id: account.id, filter_id: custom_filter.id)] }
  end

  def built_in_filter_version_for(user)
    store.built_in_filter_version(account_id: account.id, user_id: user.id)
  end

  def redis_keys
    base_redis_keys + custom_filter_version_keys
  end

  def base_redis_keys
    [
      store.conversation_version_key(account.id),
      *built_in_filter_version_keys,
      store.folder_index_version_key(account.id, user.id),
      store.filter_version_key(account.id, filter_id),
      store.filter_count_key(account.id, filter_id)
    ]
  end

  def built_in_filter_version_keys
    [user.id, other_user.id].map { |user_id| store.built_in_filter_version_key(account.id, user_id) }
  end

  def custom_filter_version_keys
    CustomFilter.where(account_id: account.id).pluck(:id).map { |id| store.filter_version_key(account.id, id) }
  end
end
