class InternalTasks::CreateService
  pattr_initialize [:conversation!, :user!, :params!]

  def perform
    template = find_template
    priority = resolve_priority(template)
    due_at = resolve_due_at(template)

    conversation.internal_tasks.create!(
      account_id: conversation.account_id,
      created_by: user,
      task_template: template,
      title: params[:title].presence || template&.title || 'Task',
      description: params[:description],
      metadata: params[:metadata] || {},
      assigned_to_id: params[:assigned_to_id],
      team_id: params[:team_id] || template&.default_team_id,
      status: 'pending',
      priority: priority,
      due_at: due_at,
      depends_on_task_id: params[:depends_on_task_id],
      source_message_id: params[:source_message_id]
    )
  end

  private

  def find_template
    return if params[:task_template_id].blank?

    conversation.account.task_templates.active.find(params[:task_template_id])
  end

  def resolve_priority(template)
    priority = params[:priority].presence || template&.default_priority || 'normal'
    boost_from_conversation(priority)
  end

  def boost_from_conversation(priority)
    conv_priority = conversation.priority
    boosted = priority

    if conv_priority.in?(%w[high urgent])
      rank = { 'normal' => 0, 'high' => 1, 'urgent' => 2 }
      conv_mapped = conv_priority == 'urgent' ? 'urgent' : 'high'
      boosted = rank[boosted] >= rank[conv_mapped] ? boosted : conv_mapped
    end

    return 'urgent' if conversation.label_list.include?('cliente_vip')

    boosted
  end

  def resolve_due_at(template)
    return Time.zone.parse(params[:due_at]) if params[:due_at].present?
    return unless template&.default_due_offset_hours

    template.default_due_offset_hours.hours.from_now
  end
end
