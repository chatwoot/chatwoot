class Flows::HandoffService
  PREVIEW_LENGTH = 60

  def initialize(run:, policy: {})
    @run = run
    @policy = policy.with_indifferent_access
    @conversation = run.conversation
    @flow = run.flow
  end

  def perform
    content = build_summary
    Messages::MessageBuilder.new(
      nil,
      @conversation,
      {
        content: content,
        private: true,
        content_attributes: { flow_run_id: @run.id, flow_event: 'handoff_summary' }
      }
    ).perform
  end

  private

  def build_summary
    lines = []
    lines << I18n.t('flows.handoff_note.ended', name: @flow.name, state: human_state)
    lines << I18n.t('flows.handoff_note.reason', reason: human_reason) if human_reason.present?

    path_lines = build_path_lines
    if path_lines.any?
      lines << I18n.t('flows.handoff_note.path_header')
      path_lines.each_with_index do |line, i|
        lines << "#{i + 1}. #{line}"
      end
    end

    vars = visible_variables
    lines << I18n.t('flows.handoff_note.variables', vars: vars.to_json) if vars.present?

    lines.join("\n")
  end

  def human_state
    case @run.state.to_s
    when 'handed_off' then I18n.t('flows.handoff_note.state_handed_off')
    when 'failed' then I18n.t('flows.handoff_note.state_failed')
    when 'cancelled' then I18n.t('flows.handoff_note.state_cancelled')
    else @run.state.to_s
    end
  end

  def human_reason
    reason = @run.ended_reason.to_s
    return if reason.blank?

    # Prefer button title when reason was baked as "Chose {value}"
    matched = last_match_from_trail
    return reason if matched.blank?

    title = button_title_for(matched[:actions_node], matched[:label])
    return reason if title.blank? || title == matched[:label]

    reason.sub(matched[:label].to_s, title)
  end

  def build_path_lines
    trail = Array(@run.trail)
    lines = []
    i = 0
    while i < trail.length
      entry = trail[i].with_indifferent_access
      node = @flow.find_node(entry[:node_id])
      result = normalize_result(entry[:result])

      if node && %w[actions send_message].include?(node['type'])
        preview = node_preview(node)
        next_entry = trail[i + 1]&.with_indifferent_access
        next_result = normalize_result(next_entry&.dig(:result))

        # Pair actions → wait_response match when present
        if next_entry && next_result.is_a?(Hash) && next_result[:matched].present?
          label = next_result[:matched]
          title = button_title_for(node, label) || label
          input = next_result[:input].presence
          choice = input.present? && input.to_s != label.to_s && input.to_s != title.to_s ? "#{title} (#{input})" : title
          lines << I18n.t('flows.handoff_note.path_choice', message: preview, choice: choice)
          i += 2
          next
        end

        lines << preview
      elsif result.is_a?(Hash) && result[:matched].present?
        # Orphan wait match without preceding actions in window
        title = result[:matched]
        lines << I18n.t('flows.handoff_note.path_chose', choice: title)
      end
      # skip wait_response / handoff / end without match pairing

      i += 1
    end
    lines
  end

  def last_match_from_trail
    Array(@run.trail).reverse_each do |raw|
      entry = raw.with_indifferent_access
      result = normalize_result(entry[:result])
      next unless result.is_a?(Hash) && result[:matched].present?

      wait_id = entry[:node_id].to_s
      actions_id = wait_id.sub(/_wait\z/, '')
      actions_node = @flow.find_node(actions_id)
      return { label: result[:matched], input: result[:input], actions_node: actions_node }
    end
    nil
  end

  def button_title_for(actions_node, label)
    return if actions_node.blank? || label.blank?

    buttons = Array(actions_node.dig('data', 'buttons'))
    btn = buttons.find { |b| (b['value'].presence || b['title']) == label } ||
          buttons.find { |b| b['title'] == label }
    btn&.dig('title').presence
  end

  def node_preview(node)
    actions = Array(node.dig('data', 'actions'))
    send = actions.find { |a| a['action_name'] == 'send_message' }
    if send
      content = Array(send['action_params']).first || send['action_params']
      if content.is_a?(String) && content.strip.present?
        truncated = content.strip.truncate(PREVIEW_LENGTH)
        return "\"#{truncated}\""
      end
    end

    if node['type'] == 'send_message'
      content = node.dig('data', 'content').to_s.strip
      return "\"#{content.truncate(PREVIEW_LENGTH)}\"" if content.present?
    end

    first = actions.first&.dig('action_name')
    first.present? ? first.humanize : node['id']
  end

  def normalize_result(result)
    return result.with_indifferent_access if result.is_a?(Hash)

    result
  end

  def visible_variables
    vars = @run.variables
    return if vars.blank?

    vars.reject { |k, _| k.to_s.start_with?('_') }
  end
end
