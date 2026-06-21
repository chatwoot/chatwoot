module Captain::ChatGenerationPath
  private

  # Ordered trace of tool executions during a run: [{ 'tool' =>, 'arguments' =>, 'result' => }].
  # Consumed by the assistant chat service to persist the generation path on the message.
  def generation_path
    @generation_path ||= []
  end

  def track_generation_step(tool_call)
    generation_path << {
      'tool' => tool_call.name.to_s,
      'arguments' => tool_call.try(:arguments)
    }
  end

  def record_generation_step_result(result)
    step = generation_path.find { |s| !s.key?('result') }
    return if step.blank?

    step['result'] = result.to_s.truncate(2000)
  end
end
