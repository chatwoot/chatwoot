class Wootql::Error < StandardError
  def evidence = @evidence || []
  def context = @context || []

  # Attach observations where their meaning is known, rather than reconstructing a
  # diagnosis from exception text at the tool boundary. Wrappers preserve these facts.
  def with_feedback(*facts, context: [])
    @evidence = (evidence + facts).uniq
    @context = (self.context + context).uniq
    self
  end
end
