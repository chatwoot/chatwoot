# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'new_relic/helper'
require 'new_relic/agent/attribute_filter'
require 'new_relic/collection_helper'

# This class encapsulates an error that was noticed by New Relic in a managed app.
class NewRelic::NoticedError
  extend NewRelic::CollectionHelper

  attr_accessor :path, :timestamp, :message, :exception_class_name,
    :request_uri, :request_port, :file_name, :line_number,
    :stack_trace, :attributes_from_notice_error, :attributes,
    :expected, :transaction_id

  attr_reader :error_group, :exception_id, :is_internal

  STRIPPED_EXCEPTION_REPLACEMENT_MESSAGE = "Message removed by New Relic 'strip_exception_messages' setting"
  UNKNOWN_ERROR_CLASS_NAME = 'Error'
  NIL_ERROR_MESSAGE = '<no message>'

  USER_ATTRIBUTES = 'userAttributes'
  AGENT_ATTRIBUTES = 'agentAttributes'
  INTRINSIC_ATTRIBUTES = 'intrinsics'

  DESTINATION = NewRelic::Agent::AttributeFilter::DST_ERROR_COLLECTOR

  AGENT_ATTRIBUTE_ERROR_GROUP = :'error.group.name'

  ERROR_PREFIX_KEY = 'error'
  ERROR_MESSAGE_KEY = "#{ERROR_PREFIX_KEY}.message"
  ERROR_CLASS_KEY = "#{ERROR_PREFIX_KEY}.class"
  ERROR_EXPECTED_KEY = "#{ERROR_PREFIX_KEY}.expected"

  def initialize(path, exception, timestamp = Process.clock_gettime(Process::CLOCK_REALTIME), expected = false)
    @exception_id = exception.object_id
    @path = path

    # It's critical that we not hold onto the exception class constant in this
    # class. These objects get serialized for Resque to a process that might
    # not have the original exception class loaded, so do all processing now
    # while we have the actual exception!
    @is_internal = (exception.class < NewRelic::Agent::InternalAgentError)

    extract_class_name_and_message_from(exception)
    @transaction_id = NewRelic::Agent::Tracer&.current_transaction&.guid

    # clamp long messages to 4k so that we don't send a lot of
    # overhead across the wire
    @message = @message[0..4095] if @message.length > 4096

    # replace error message if enabled
    if NewRelic::Agent.config[:'strip_exception_messages.enabled'] &&
        !self.class.passes_message_allowlist(exception.class)
      @message = STRIPPED_EXCEPTION_REPLACEMENT_MESSAGE
    end

    @attributes_from_notice_error = nil
    @attributes = nil
    @timestamp = timestamp
    @expected = expected
  end

  def ==(other)
    if other.respond_to?(:exception_id)
      exception_id == other.exception_id
    else
      false
    end
  end

  def self.passes_message_allowlist(exception_class)
    NewRelic::Agent.config[:'strip_exception_messages.allowed_classes'].any? do |klass|
      exception_class <= klass
    end
  end

  include NewRelic::Coerce

  def to_collector_array(encoder = nil)
    arr = [NewRelic::Helper.time_to_millis(timestamp),
      string(path),
      string(message),
      string(exception_class_name),
      processed_attributes]
    arr << @transaction_id if @transaction_id
    arr
  end

  # Note that we process attributes lazily and store the result. This is because
  # there is a possibility that a noticed error will be discarded and not sent back
  # as a traced error or TransactionError.
  def processed_attributes
    @processed_attributes ||= begin
      attributes = base_parameters
      merged_attributes = NewRelic::Agent::Attributes.new(NewRelic::Agent.instance.attribute_filter)
      append_attributes(attributes, USER_ATTRIBUTES, merged_custom_attributes(merged_attributes))
      append_attributes(attributes, AGENT_ATTRIBUTES, build_agent_attributes(merged_attributes))
      append_attributes(attributes, INTRINSIC_ATTRIBUTES, build_intrinsic_attributes)
      attributes
    end
  end

  def base_parameters
    params = {}
    params[:file_name] = file_name if file_name
    params[:line_number] = line_number if line_number
    params[:stack_trace] = stack_trace if stack_trace
    params[ERROR_EXPECTED_KEY.to_sym] = expected
    params
  end

  # We can get custom attributes from two sources--the transaction, which we
  # hold in @attributes, or passed options to notice_error which show up in
  # @attributes_from_notice_error. Both need filtering, so merge them together
  # in our Attributes class for consistent handling
  def merged_custom_attributes(merged_attributes)
    merge_custom_attributes_from_transaction(merged_attributes)
    merge_custom_attributes_from_notice_error(merged_attributes)

    merged_attributes.custom_attributes_for(DESTINATION)
  end

  def merge_custom_attributes_from_transaction(merged_attributes)
    if @attributes
      from_transaction = @attributes.custom_attributes_for(DESTINATION)
      merged_attributes.merge_custom_attributes(from_transaction)
    end
  end

  def merge_custom_attributes_from_notice_error(merged_attributes)
    if @attributes_from_notice_error
      from_notice_error = NewRelic::NoticedError.normalize_params(@attributes_from_notice_error)
      merged_attributes.merge_custom_attributes(from_notice_error)
    end
  end

  def build_error_attributes
    @attributes_from_notice_error ||= {}
    @attributes_from_notice_error[ERROR_MESSAGE_KEY] = string(message)
    @attributes_from_notice_error[ERROR_CLASS_KEY] = string(exception_class_name)

    @attributes_from_notice_error[ERROR_EXPECTED_KEY] = true if expected
  end

  def build_agent_attributes(merged_attributes)
    return NewRelic::EMPTY_HASH unless @attributes

    @attributes.agent_attributes_for(DESTINATION)
  end

  def build_intrinsic_attributes
    if @attributes
      @attributes.intrinsic_attributes_for(DESTINATION)
    else
      NewRelic::EMPTY_HASH
    end
  end

  def append_attributes(outgoing_params, outgoing_key, source_attributes)
    outgoing_params[outgoing_key] = source_attributes || {}
  end

  def agent_attributes
    processed_attributes[AGENT_ATTRIBUTES]
  end

  def custom_attributes
    processed_attributes[USER_ATTRIBUTES]
  end

  def intrinsic_attributes
    processed_attributes[INTRINSIC_ATTRIBUTES]
  end

  def extract_class_name_and_message_from(exception)
    if exception.nil?
      @exception_class_name = UNKNOWN_ERROR_CLASS_NAME
      @message = NIL_ERROR_MESSAGE
    elsif exception.is_a?(NewRelic::Agent::NoticeableError)
      @exception_class_name = exception.class_name
      @message = exception.message
    else
      if defined?(Rails::VERSION::MAJOR) && Rails::VERSION::MAJOR < 5 && exception.respond_to?(:original_exception)
        exception = exception.original_exception || exception
      end
      @exception_class_name = exception.is_a?(Exception) ? exception.class.name : UNKNOWN_ERROR_CLASS_NAME
      @message = exception.to_s
    end
  end

  def error_group=(name)
    return if name.nil? || name.empty?

    if agent_attributes.frozen?
      processed_attributes[AGENT_ATTRIBUTES] = agent_attributes.merge(AGENT_ATTRIBUTE_ERROR_GROUP => name)
    else
      agent_attributes[AGENT_ATTRIBUTE_ERROR_GROUP] = name
    end

    @error_group = name
  end
end
