class Captain::Copilot::Actions::SetStatus < Captain::Copilot::Actions::BaseAction
  NAME = 'set_status'.freeze
  RESOURCE = 'conversations'.freeze
  DESCRIPTION = "Set the status of each conversation. Arguments: status, one of #{Conversation.statuses.keys.join(', ')}; " \
                'snoozed_until, an ISO 8601 time in the future, only with snoozed. A conversation snoozed without ' \
                'snoozed_until opens again when the customer replies.'.freeze
  ARGUMENTS = {
    type: 'object', additionalProperties: false, required: %w[status],
    properties: { status: { type: 'string', enum: Conversation.statuses.keys }, snoozed_until: { type: %w[string null] } }
  }.deep_stringify_keys.freeze

  # The same write as the dashboard's bulk status change. Resolving runs the CSAT survey as it does there.
  def perform(conversation)
    return :skipped if conversation.status == status && conversation.snoozed_until == snoozed_until

    conversation.update!(status: status, snoozed_until: snoozed_until)
    :applied
  end

  def card(ids)
    return super.merge(summary: 'SET_STATUS_SNOOZED_UNTIL', values: { time: snoozed_until.to_i }) if snoozed_until

    card = { summary: "SET_STATUS_#{status.upcase}" }
    card[:warning] = 'CSAT_SURVEY' if status == 'resolved' && @account.conversations.where(id: ids).joins(:inbox)
                                                                      .exists?(inboxes: { csat_survey_enabled: true })
    card
  end

  private

  def status
    @arguments['status']
  end

  def snoozed_until
    return unless @arguments['snoozed_until']

    @snoozed_until ||= Time.zone.iso8601(@arguments['snoozed_until'])
  rescue ArgumentError
    raise ArgumentError, 'snoozed_until must be an ISO 8601 time'
  end

  # Checked again before each batch, so a snooze time that passed before the agent approved stops the change.
  def validate!
    return unless snoozed_until
    raise ArgumentError, 'snoozed_until works only with status snoozed' unless status == 'snoozed'
    raise ArgumentError, 'snoozed_until must be in the future' unless snoozed_until.future?
  end
end
