class Flows::EvaluatorService
  def initialize(run:, message:)
    @run = run
    @message = message
  end

  def perform
    return unless @run.waiting?

    node = @run.current_node
    return Flows::ExitPolicyService.new(run: @run, event: 'on_fail', reason: 'missing_wait_node').perform if node.blank? || node['type'] != 'wait_response'

    label = match_label(node)
    if label.blank?
      Flows::ExitPolicyService.new(run: @run, event: 'on_fail', reason: 'no_match').perform
      return
    end

    edge = @run.flow.edges_from(node['id']).find do |e|
      when_clause = (e['when'] || {}).with_indifferent_access
      when_clause[:match_label].to_s == label.to_s
    end

    if edge.blank?
      Flows::ExitPolicyService.new(run: @run, event: 'on_fail', reason: "no_edge_for:#{label}").perform
      return
    end

    @run.append_to_trail!(node['id'], { 'matched' => label, 'input' => customer_input })
    FlowEvent.create!(
      flow_run: @run,
      event_type: 'matched',
      node_id: node['id'],
      data: { label: label, input: customer_input },
      created_at: Time.current
    )
    Flows::ExecutionService.new(run: @run).advance_to!(edge['to'])
  end

  private

  def customer_input
    @customer_input ||= begin
      raw = @message.content.to_s.strip
      # WhatsApp button replies often put the title in content; interactive id may be in content_attributes
      attrs = @message.content_attributes || {}
      raw.presence || attrs['submitted_values']&.first&.dig('value').to_s || attrs['button_payload'].to_s
    end
  end

  def match_label(node)
    matches = Array(node.dig('data', 'match'))
    input = customer_input.downcase

    matches.each do |m|
      m = m.with_indifferent_access
      label = m[:label].to_s
      pattern = m[:pattern].presence || "^#{Regexp.escape(label)}$"
      begin
        return label if Regexp.new(pattern, Regexp::IGNORECASE).match?(customer_input) ||
                        input == label.downcase ||
                        input == m[:value].to_s.downcase
      rescue RegexpError
        next
      end
    end

    # Fallback: match button title/value equality without regex
    matches.each do |m|
      m = m.with_indifferent_access
      return m[:label].to_s if [m[:label], m[:value]].compact.map { |v| v.to_s.downcase }.include?(input)
    end

    nil
  end
end
