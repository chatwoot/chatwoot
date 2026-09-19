# frozen_string_literal: true

module Integrations::LlmInstrumentationContext
  LANGFUSE_ATTRIBUTES_KEY = :llm_instrumentation_langfuse_attributes
  LANGFUSE_OBSERVATION_METADATA_KEY = :llm_instrumentation_langfuse_observation_metadata_attributes

  private

  def with_propagated_langfuse_attributes(params)
    previous_attributes = current_langfuse_attributes
    previous_observation_metadata_attributes = current_observation_metadata_attributes
    self.current_langfuse_attributes = previous_attributes.merge(propagated_langfuse_attributes(params))
    self.current_observation_metadata_attributes = previous_observation_metadata_attributes.merge(propagated_observation_metadata_attributes(params))

    yield
  ensure
    self.current_langfuse_attributes = previous_attributes
    self.current_observation_metadata_attributes = previous_observation_metadata_attributes
  end

  def apply_current_langfuse_attributes(span)
    set_langfuse_attributes(span, current_langfuse_attributes)
    set_langfuse_attributes(span, current_observation_metadata_attributes)
  end

  def current_langfuse_attributes
    ActiveSupport::IsolatedExecutionState[LANGFUSE_ATTRIBUTES_KEY] || {}
  end

  def current_langfuse_attributes=(attrs)
    ActiveSupport::IsolatedExecutionState[LANGFUSE_ATTRIBUTES_KEY] = attrs
  end

  def current_observation_metadata_attributes
    ActiveSupport::IsolatedExecutionState[LANGFUSE_OBSERVATION_METADATA_KEY] || {}
  end

  def current_observation_metadata_attributes=(attrs)
    ActiveSupport::IsolatedExecutionState[LANGFUSE_OBSERVATION_METADATA_KEY] = attrs
  end
end
