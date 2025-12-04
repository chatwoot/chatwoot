# frozen_string_literal: true

module Captain::Providers::Gemini::Chat
  # TODO: Implement Gemini chat using HTTP requests to:
  # POST https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={API_KEY}
  #
  # Key implementation notes:
  # - tools: should be an array [{ functionDeclarations: [...] }]
  # - contents: array of { role: 'user'|'model', parts: [{ text: '...' }] }
  # - systemInstruction: { parts: [{ text: '...' }] }
  # - Handle markdown code blocks in response (```json ... ```)
  # - Handle tool_calls messages (messages with nil content)
  # - Gemini uses 'model' role instead of 'assistant'
  # - Gemini requires alternating user/model turns
  def chat(parameters:)
    raise NotImplementedError, 'Gemini chat is not yet implemented. Please use OpenAI provider.'
  end
end
