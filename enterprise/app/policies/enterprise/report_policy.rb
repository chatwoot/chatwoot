module Enterprise::ReportPolicy
  ACTION_PERMISSIONS = {
    'overview_summary' => 'report_overview',
    'conversation_metrics' => 'report_overview',
    'grouped_conversation_metrics' => 'report_overview',
    'agent_activity' => 'report_agent_activity',
    'agents' => 'report_agent',
    'agent' => 'report_agent',
    'labels' => 'report_label',
    'label' => 'report_label',
    'inboxes' => 'report_inbox',
    'inbox' => 'report_inbox',
    'teams' => 'report_team',
    'team' => 'report_team',
    'bot_summary' => 'report_bot',
    'bot_summary_download' => 'report_bot',
    'bot_metrics' => 'report_bot',
    'queued_customers' => 'report_queued_customers',
    'conversations_summary' => 'report_conversation',
    'conversation_traffic' => 'report_conversation',
    'all_conversation_metrics_download' => 'report_conversation',
    'conversations' => 'report_conversation',
    'inbox_label_matrix' => 'report_inbox',
    'first_response_time_distribution' => 'report_conversation',
    'outgoing_messages_count' => 'report_conversation'
  }.freeze

  TYPE_PERMISSIONS = {
    'agent' => 'report_agent',
    'label' => 'report_label',
    'inbox' => 'report_inbox',
    'team' => 'report_team',
    'account' => 'report_overview'
  }.freeze

  def view?
    @account_user.custom_role_permission?('report_manage') || report_page_permitted? || super
  end

  private

  def report_page_permitted?
    permission = report_permission_for_record
    permission.present? && @account_user.custom_role_permission?(permission)
  end

  def report_permission_for_record
    action = record_action
    return TYPE_PERMISSIONS[record_type] if ReportPolicy::SHARED_ACTIONS.include?(action)

    ACTION_PERMISSIONS[action]
  end
end
