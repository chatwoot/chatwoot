class Captain::Copilot::Actions::AddParticipants < Captain::Copilot::Actions::BaseAction
  NAME = 'add_participants'.freeze
  RESOURCE = 'conversations'.freeze
  DESCRIPTION = 'Add agents as participants of each conversation. Arguments: user_ids, user IDs from get_account_directory. ' \
                'An agent who is not a member of the inbox is not added.'.freeze
  ARGUMENTS = {
    type: 'object', additionalProperties: false, required: %w[user_ids],
    properties: { user_ids: { type: 'array', minItems: 1, maxItems: 10, uniqueItems: true, items: { type: 'integer', minimum: 1 } } }
  }.deep_stringify_keys.freeze

  # The same write as the dashboard's participants menu, which offers only inbox members and administrators.
  def perform(conversation)
    new_ids = user_ids - conversation.conversation_participants.pluck(:user_id)
    return :skipped if new_ids.empty?

    outside = new_ids - conversation.inbox.assignable_agents.map(&:id)
    if outside.any?
      raise Captain::Copilot::ActionNotApplicableError,
            "Not members of the #{conversation.inbox.name} inbox: #{users.values_at(*outside).map(&:name).join(', ')}"
    end

    new_ids.each { |id| conversation.conversation_participants.create!(user_id: id) }
    :applied
  end

  def card(_ids)
    super.merge(values: { agents: users.values_at(*user_ids).map(&:name).join(', ') })
  end

  private

  def user_ids
    @arguments['user_ids']
  end

  def users
    @users ||= @account.users.where(id: user_ids).index_by(&:id)
  end

  def validate!
    unknown = user_ids - users.keys
    return if unknown.empty?

    directory = @account.users.order(:name).limit(100).map { |user| "#{user.name} (ID #{user.id})" }
    raise ArgumentError, "No agent with user ID #{unknown.join(', ')} in this account. Agents: #{directory.join(', ')}"
  end
end
