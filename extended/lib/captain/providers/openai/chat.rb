# frozen_string_literal: true

module Captain::Providers::Openai::Chat
  def chat(parameters:)
    # Handle optional parameters
    params = parameters.dup
    add_optional_parameters(params)

    result = @client.chat(parameters: params)
    handle_error(result) if result['error']
    result
  end

  private

  def add_optional_parameters(parameters)
    # Optional parameters are already in the hash, no need to extract
    # Just ensure they're passed through correctly
    parameters
  end
end
