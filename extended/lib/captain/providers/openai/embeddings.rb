# frozen_string_literal: true

module Captain::Providers::Openai::Embeddings
  def embeddings(parameters:)
    result = @client.embeddings(parameters: parameters)
    handle_error(result) if result['error']
    result
  end
end
