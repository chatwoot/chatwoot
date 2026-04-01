class Llm::Credential < Data.define(:api_key, :source)
  def system?
    source == :system
  end
end
