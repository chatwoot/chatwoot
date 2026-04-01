Llm::Credential = Data.define(:api_key, :source) do
  def system?
    source == :system
  end
end
