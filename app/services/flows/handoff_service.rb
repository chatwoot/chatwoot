class Flows::HandoffService
  def initialize(run:, policy: {})
    @run = run
    @policy = policy.with_indifferent_access
    @conversation = run.conversation
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
    lines << "Automation flow \"#{@run.flow.name}\" ended (#{@run.state})."
    lines << "Reason: #{@run.ended_reason}" if @run.ended_reason.present?
    lines << "Last node: #{@run.current_node_id}"
    lines << "Variables: #{@run.variables.to_json}" if @run.variables.present?
    trail = Array(@run.trail).last(8)
    lines << "Steps: #{trail.map { |t| t['node_id'] }.compact.join(' → ')}" if trail.any?
    lines.join("\n")
  end
end
