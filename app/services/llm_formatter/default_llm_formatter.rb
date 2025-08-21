class LlmFormatter::DefaultLlmFormatter
  def initialize(record)
    @record = record
  end

  def format(*)
    # override this
  end
end
