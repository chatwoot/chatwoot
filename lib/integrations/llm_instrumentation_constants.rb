# frozen_string_literal: true

module Integrations::LlmInstrumentationConstants
  # OpenTelemetry attribute names following GenAI semantic conventions
  # https://opentelemetry.io/docs/specs/semconv/gen-ai/
  ATTR_GEN_AI_PROVIDER = 'gen_ai.provider.name'
  ATTR_GEN_AI_REQUEST_MODEL = 'gen_ai.request.model'
  ATTR_GEN_AI_REQUEST_TEMPERATURE = 'gen_ai.request.temperature'
  ATTR_GEN_AI_PROMPT_ROLE = 'gen_ai.prompt.%d.role'
  ATTR_GEN_AI_PROMPT_CONTENT = 'gen_ai.prompt.%d.content'
  ATTR_GEN_AI_COMPLETION_ROLE = 'gen_ai.completion.0.role'
  ATTR_GEN_AI_COMPLETION_CONTENT = 'gen_ai.completion.0.content'
  ATTR_GEN_AI_USAGE_INPUT_TOKENS = 'gen_ai.usage.input_tokens'
  ATTR_GEN_AI_USAGE_OUTPUT_TOKENS = 'gen_ai.usage.output_tokens'
  ATTR_GEN_AI_USAGE_TOTAL_TOKENS = 'gen_ai.usage.total_tokens'
  ATTR_GEN_AI_RESPONSE_ERROR = 'gen_ai.response.error'
  ATTR_GEN_AI_RESPONSE_ERROR_CODE = 'gen_ai.response.error_code'

  TOOL_SPAN_NAME = 'tool.%s'

  # Langfuse-specific attributes
  # https://langfuse.com/integrations/native/opentelemetry#property-mapping
  ATTR_LANGFUSE_USER_ID = 'langfuse.user.id'
  ATTR_LANGFUSE_SESSION_ID = 'langfuse.session.id'
  ATTR_LANGFUSE_TAGS = 'langfuse.trace.tags'
  ATTR_LANGFUSE_METADATA = 'langfuse.trace.metadata.%s'
  ATTR_LANGFUSE_TRACE_INPUT = 'langfuse.trace.input'
  ATTR_LANGFUSE_TRACE_OUTPUT = 'langfuse.trace.output'
  ATTR_LANGFUSE_OBSERVATION_TYPE = 'langfuse.observation.type'
  ATTR_LANGFUSE_OBSERVATION_INPUT = 'langfuse.observation.input'
  ATTR_LANGFUSE_OBSERVATION_OUTPUT = 'langfuse.observation.output'
end
