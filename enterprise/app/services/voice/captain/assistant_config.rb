# The Vapi assistant for one call, built from the inbox's Captain assistant: its instructions, its model,
# and its tools, which Vapi runs by calling our webhook.
class Voice::Captain::AssistantConfig
  MAX_CALL_SECONDS = 30.minutes.to_i
  # Vapi's denoisers drift on Twilio's bypass stream and stop passing the caller's audio to the transcriber
  DENOISING_OFF = { smartDenoisingPlan: { enabled: false }, fourierDenoisingPlan: { enabled: false } }.freeze

  pattr_initialize [:assistant!]

  def to_h
    {
      name: assistant.name.truncate(40),
      firstMessage: first_message,
      model: {
        provider: 'openai',
        model: assistant.agent_model,
        temperature: assistant.temperature.presence&.to_f || Concerns::Agentable::DEFAULT_TEMPERATURE,
        messages: [{ role: 'system', content: system_prompt }],
        tools: tools
      },
      server: server,
      serverMessages: ['end-of-call-report'],
      analysisPlan: { summaryPrompt: summary_prompt },
      backgroundSpeechDenoisingPlan: DENOISING_OFF,
      # Vapi plays office ambience behind phone calls unless this is off
      backgroundSound: 'off',
      maxDurationSeconds: MAX_CALL_SECONDS
    }
  end

  private

  def first_message
    "Hi, you're speaking with #{assistant.name}, an AI assistant for #{product_name}. How can I help you today?"
  end

  def product_name
    assistant.config['product_name'].presence || assistant.account.name
  end

  def system_prompt
    [
      "You are #{assistant.name}, an AI assistant answering phone calls for #{product_name}.",
      assistant.description,
      voice_rules,
      list_section('Response guidelines', assistant.response_guidelines),
      list_section('Guardrails', assistant.guardrails)
    ].compact_blank.join("\n\n")
  end

  def voice_rules
    <<~RULES
      You are on a live phone call. Your replies are spoken aloud.
      - Keep each reply to one or two short sentences in plain spoken language. No lists, links, markdown or emoji.
      - If asked, say that you are an AI assistant.
      - Before answering a question about the product, search the FAQs and answer only from the results. Never make up an answer.
      - When the caller asks for a person, or you cannot help, hand off to the team. The caller is then connected to an agent.
      - When the caller's question is answered and they have nothing else, say goodbye and end the call.
    RULES
  end

  def list_section(title, items)
    return if items.blank?

    "#{title}:\n#{Array(items).map { |item| "- #{item}" }.join("\n")}"
  end

  def summary_prompt
    'Summarize this support call in two or three sentences for the agent who reads it next: ' \
      'what the caller wanted, what was answered, and anything still open.'
  end

  def tools
    assistant.agent.tools.map { |tool| function_tool(tool) } + [{ type: 'endCall' }]
  end

  def function_tool(tool)
    {
      type: 'function',
      function: {
        name: tool.name,
        description: tool.description,
        # RubyLLM puts OpenAI's function-level `strict` flag inside the schema, and Vapi rejects it there
        parameters: tool.parameters_schema.to_h.except('strict', :strict)
      },
      server: server,
      messages: [{ type: 'request-start', content: request_start_message(tool) }]
    }
  end

  def request_start_message(tool)
    return 'Sure, connecting you to someone from our team now.' if tool.is_a?(::Captain::Tools::HandoffTool)

    'One moment.'
  end

  # Vapi doesn't attach stored credentials to a server URL sent in the request, so the secret goes in the headers
  def server
    {
      url: Rails.application.routes.url_helpers.vapi_webhook_url,
      headers: { Voice::Captain::WebhookAuth::HEADER => Voice::Captain::VapiConfig.webhook_secret }
    }
  end
end
