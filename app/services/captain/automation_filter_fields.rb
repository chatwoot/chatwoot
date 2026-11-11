# The automation rule condition fields Jev may recommend, limited to the keys the rule's event offers.
# Operators and multiple values follow what the automation form offers for each condition.
# Languages and country are left out because their options exceed MAX_OPTIONS.
class Captain::AutomationFilterFields
  include Captain::FilterFieldBuilder
  include Captain::FilterWording

  SUBJECT = 'support conversations, or the messages in them, that an automation rule should act on'.freeze
  MESSAGE_TYPE_OPTIONS = [['incoming', 'Incoming, sent by the customer'], ['outgoing', 'Outgoing, sent by an agent']].freeze
  PRIVATE_NOTE_OPTIONS = [[true, 'A private note'], [false, 'Not a private note']].freeze
  CAPTAIN_OPERATORS = %w[detects does_not_detect].freeze
  IGNORE_ACTIONS = 'Ignore what the rule does when it runs, such as adding a label, assigning or replying.'.freeze

  # `attribute_keys` lists the condition keys the rule's event offers, from the automation form.
  pattr_initialize [:account!, :user!, :attribute_keys!]

  def subject
    SUBJECT
  end

  def all
    catalog.select { |field| attribute_keys.include?(field[:key]) }.first(MAX_FIELDS)
  end

  # A rule's description also says what the rule does. The filter wording read "Add label bug" as
  # "conversations whose label is bug", so these questions ask what the rule checks before it runs.
  def relevance_question_text(field)
    "Does the automation rule described by `description` only run when a condition on \"#{field[:label]}\" holds? " \
      "#{IGNORE_ACTIONS}"
  end

  def option_question_text(field, option)
    "Does the automation rule described by `description` only run when \"#{field[:label]}\" is \"#{option[:label]}\"? " \
      "#{IGNORE_ACTIONS}"
  end

  private

  def catalog
    conversation_fields + conversation_text_fields + message_fields + contact_fields + [captain_condition_field] +
      list_attribute_fields(:conversation_attribute) + list_attribute_fields(:contact_attribute)
  end

  def conversation_fields
    [
      field('status', 'Status', EQUALITY_OPERATORS, Conversation.statuses.keys.map { |status| [status, status] }, multiple: true),
      field('priority', 'Priority', EQUALITY_OPERATORS, Conversation.priorities.keys.map { |priority| [priority, priority] },
            multiple: true, ordered: true),
      field('assignee_id', 'Assigned agent', PRESENCE_OPERATORS, options(account.users, :id, :name)),
      field('team_id', 'Team', PRESENCE_OPERATORS, options(account.teams, :id, :name)),
      field('inbox_id', 'Inbox', EQUALITY_OPERATORS, options(account.inboxes, :id, :name), multiple: true),
      field('labels', 'Label', PRESENCE_OPERATORS, options(account.labels, :title, :title), multiple: true)
    ]
  end

  def conversation_text_fields
    [
      text_field('mail_subject', 'Email subject', CONTAINMENT_OPERATORS),
      text_field('referer', 'Referer link, the page the conversation started from', CONTAINMENT_OPERATORS)
    ]
  end

  def message_fields
    [
      field('message_type', 'Message type', EQUALITY_OPERATORS, MESSAGE_TYPE_OPTIONS),
      field('private_note', 'Private note', EQUALITY_OPERATORS, PRIVATE_NOTE_OPTIONS),
      text_field('content', 'Message content', CONTAINMENT_OPERATORS)
    ]
  end

  def contact_fields
    [
      text_field('email', 'Contact email address, or its domain such as example.com', CONTAINMENT_OPERATORS),
      text_field('phone_number', 'Contact phone number', CONTAINMENT_OPERATORS),
      text_field('company_name', 'Contact company', CONTAINMENT_OPERATORS),
      text_field('city', 'Contact city', CONTAINMENT_OPERATORS)
    ]
  end

  # Captain judges this condition from the messages when the rule runs, so its value is the part of the
  # description that no other field can express, such as a topic or the customer's tone.
  def captain_condition_field
    text_field('captain_condition', 'Captain condition, a topic, intent or tone that AI judges from the messages, ' \
                                    'without what the rule does, such as tag, label, assign or escalate', CAPTAIN_OPERATORS)
  end
end
