class LlmFormatter::DefaultLlmFormatter
  def initialize(record)
    @record = record
  end

  def format(config)
    # override this
  end
end
