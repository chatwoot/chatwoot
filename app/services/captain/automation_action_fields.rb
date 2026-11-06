# The automation rule actions Jev may recommend, limited to the action names the form offers.
# Each action's label says what it does. Its parameters are the options, or the words of the description for text.
# Actions that need a file, a URL, email addresses or an SLA policy are left out.
class Captain::AutomationActionFields
  include Captain::FilterFieldBuilder
  include Captain::ActionWording

  NO_PARAMETER_ACTIONS = {
    'remove_assigned_agent' => 'Unassign the agent from the conversation',
    'remove_assigned_team' => 'Remove the team from the conversation',
    'mute_conversation' => 'Mute the conversation',
    'snooze_conversation' => 'Snooze the conversation',
    'resolve_conversation' => 'Resolve the conversation',
    'open_conversation' => 'Open or reopen the conversation',
    'pending_conversation' => 'Mark the conversation as pending'
  }.freeze

  # `action_names` lists the actions the automation form offers.
  pattr_initialize [:account!, :user!, :action_names!]

  def all
    catalog.select { |field| action_names.include?(field[:key]) }.first(MAX_FIELDS)
  end

  private

  def catalog
    option_actions + text_actions + NO_PARAMETER_ACTIONS.map { |key, label| action(key, label, []) }
  end

  def option_actions
    [
      action('add_label', 'Add a label to the conversation', options(account.labels, :title, :title), multiple: true),
      action('remove_label', 'Remove a label from the conversation', options(account.labels, :title, :title), multiple: true),
      action('assign_agent', 'Assign the conversation to an agent', options(account.users, :id, :name)),
      action('assign_team', 'Assign the conversation to a team', options(account.teams, :id, :name)),
      action('change_priority', 'Change the conversation priority', Conversation.priorities.keys.map { |priority| [priority, priority] })
    ]
  end

  def text_actions
    [
      action('send_message', 'Send a message to the customer', [], text: true),
      action('add_private_note', 'Add a private note for agents', [], text: true)
    ]
  end

  def action(key, label, values, **traits)
    field(key, label, [], values, action: true, **traits)
  end
end
