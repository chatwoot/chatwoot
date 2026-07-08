class Conversations::UnreadCounts::FilteredCountInvalidator
  FEATURE_FLAG = 'unread_count_for_filters'.freeze

  attr_reader :account

  def initialize(account)
    @account = account
  end

  def conversation_changed!
    return false unless enabled?

    version = store.bump_conversation_version!(account.id)
    record_invalidation(:conversation, reason: :conversation_changed, version: version)
    true
  end

  def user_visibility_changed!(user_id:)
    return false unless enabled? && user_id.present?

    version = store.bump_built_in_filter_version!(account_id: account.id, user_id: user_id)
    record_invalidation(:built_in_filter, reason: :user_visibility_changed, version: version)
    true
  end

  def users_visibility_changed!(user_ids:)
    return false unless enabled?

    user_ids = Array(user_ids).compact_blank.uniq
    return false if user_ids.blank?

    bump_built_in_filter_versions(user_ids).each_value do |version|
      record_invalidation(:built_in_filter, reason: :user_visibility_changed, version: version)
    end
    true
  end

  def custom_filter_created!(custom_filter)
    return false unless conversation_filter?(custom_filter)

    bump_folder_index_version!(custom_filter, reason: :custom_filter_created)
    bump_filter_version!(custom_filter, reason: :custom_filter_created)
    true
  end

  def custom_filter_updated!(custom_filter)
    return false unless enabled? && conversation_filter_before_or_after?(custom_filter)

    filter_type_changed = filter_type_changed?(custom_filter)
    query_changed = query_changed?(custom_filter)
    return false unless filter_type_changed || query_changed

    bump_folder_index_version!(custom_filter, reason: :custom_filter_updated) if filter_type_changed
    bump_filter_version!(custom_filter, reason: :custom_filter_updated)
    store.delete_filter_count!(account_id: account.id, filter_id: custom_filter.id) if moved_out_of_conversation_filters?(custom_filter)
    true
  end

  def custom_filter_destroyed!(custom_filter)
    return false unless conversation_filter?(custom_filter)

    bump_folder_index_version!(custom_filter, reason: :custom_filter_destroyed)
    store.delete_filter_count!(account_id: account.id, filter_id: custom_filter.id)
    true
  end

  def custom_attribute_definition_changed!(custom_attribute_definition)
    return false unless enabled? && conversation_attribute_before_or_after?(custom_attribute_definition)

    affected_filters = affected_custom_attribute_filters(custom_attribute_definition)
    return false if affected_filters.blank?

    affected_filters.each { |custom_filter| bump_filter_version!(custom_filter, reason: :custom_attribute_definition_changed) }
    true
  end

  private

  def bump_built_in_filter_versions(user_ids)
    results = Redis::Alfred.pipelined do |pipeline|
      user_ids.each do |user_id|
        key = store.built_in_filter_version_key(account.id, user_id)
        pipeline.incr(key)
        pipeline.expire(key, Conversations::UnreadCounts::FILTERED_COUNT_VERSION_TTL)
      end
    end

    user_ids.zip(results.each_slice(2).map(&:first)).to_h
  end

  def enabled?
    account&.feature_enabled?(FEATURE_FLAG)
  end

  def conversation_filter?(custom_filter)
    enabled? && custom_filter.conversation?
  end

  def conversation_filter_before_or_after?(custom_filter)
    custom_filter.conversation? || previous_filter_type(custom_filter) == 'conversation'
  end

  def moved_out_of_conversation_filters?(custom_filter)
    filter_type_changed?(custom_filter) && previous_filter_type(custom_filter) == 'conversation' && !custom_filter.conversation?
  end

  def filter_type_changed?(custom_filter)
    custom_filter.previous_changes.key?('filter_type')
  end

  def query_changed?(custom_filter)
    custom_filter.previous_changes.key?('query')
  end

  def previous_filter_type(custom_filter)
    raw_filter_type = custom_filter.previous_changes.dig('filter_type', 0)
    return if raw_filter_type.blank?
    return raw_filter_type if CustomFilter.filter_types.key?(raw_filter_type)
    return CustomFilter.filter_types.key(raw_filter_type) if raw_filter_type.is_a?(Integer)

    CustomFilter.filter_types.key(raw_filter_type.to_i) || raw_filter_type.to_s
  end

  def conversation_attribute_before_or_after?(custom_attribute_definition)
    custom_attribute_definition.conversation_attribute? || previous_attribute_model(custom_attribute_definition) == 'conversation_attribute'
  end

  def previous_attribute_model(custom_attribute_definition)
    raw_attribute_model = custom_attribute_definition.previous_changes.dig('attribute_model', 0)
    return if raw_attribute_model.blank?
    return raw_attribute_model if CustomAttributeDefinition.attribute_models.key?(raw_attribute_model)
    return CustomAttributeDefinition.attribute_models.key(raw_attribute_model) if raw_attribute_model.is_a?(Integer)

    CustomAttributeDefinition.attribute_models.key(raw_attribute_model.to_i) || raw_attribute_model.to_s
  end

  def affected_custom_attribute_filters(custom_attribute_definition)
    attribute_keys = custom_attribute_keys(custom_attribute_definition)
    account.custom_filters.conversation.select do |custom_filter|
      custom_filter_references_conversation_attribute?(custom_filter, attribute_keys)
    end
  end

  def custom_attribute_keys(custom_attribute_definition)
    [custom_attribute_definition.attribute_key, custom_attribute_definition.previous_changes.dig('attribute_key', 0)].compact_blank.map(&:to_s).uniq
  end

  def custom_filter_references_conversation_attribute?(custom_filter, attribute_keys)
    payload = custom_filter.query.with_indifferent_access[:payload]
    Array(payload).any? do |condition|
      condition = condition.with_indifferent_access
      condition[:attribute_key].to_s.in?(attribute_keys) &&
        (condition[:custom_attribute_type].presence || 'conversation_attribute') == 'conversation_attribute'
    end
  end

  def bump_folder_index_version!(custom_filter, reason:)
    version = store.bump_folder_index_version!(account_id: account.id, user_id: custom_filter.user_id)
    record_invalidation(:folder_index, reason: reason, version: version)
  end

  def bump_filter_version!(custom_filter, reason:)
    version = store.bump_filter_version!(account_id: account.id, filter_id: custom_filter.id)
    record_invalidation(:filter, reason: reason, version: version)
  end

  def record_invalidation(scope, reason:, version:)
    instrumentation.increment(
      :invalidation,
      account_id: account.id,
      invalidation_scope: scope,
      reason: reason,
      version: version
    )
  end

  def store
    ::Conversations::UnreadCounts::FilteredCountStore
  end

  def instrumentation
    ::Conversations::UnreadCounts::FilteredCountInstrumentation
  end
end
