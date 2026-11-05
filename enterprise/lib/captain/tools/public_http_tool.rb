# A custom tool in a conversation where a customer is the user. A tool that requires email verification runs only
# for a customer who verified an email, and a verified email parameter always carries that email.
# A stored value parameter only takes a value an earlier tool of the same toolset found for that customer.
class Captain::Tools::PublicHttpTool < Captain::Tools::HttpTool
  EMAIL_REQUIRED = 'This tool needs a verified email, and this customer has not verified an email yet. ' \
                   'Verify their email with a one-time code first, then call this tool again. ' \
                   'If that is not possible, ask whether they want to talk to a support agent.'.freeze

  def perform(tool_context, **params)
    return super unless @custom_tool.requires_email_verification?

    state = tool_context.state
    verified_email = stored_verified_email(state)
    return failure_result(EMAIL_REQUIRED, state) unless verified_email

    params, reason = with_stored_values(params, tool_store(state, verified_email))
    return failure_result(reason, state) if reason

    # Set last, so a value from the model can never replace the verified email
    email_param = @custom_tool.verified_email_param
    super(tool_context, **(email_param ? params.merge(email_param.to_sym => verified_email) : params))
  end

  private

  # A blank value is filled when exactly one is stored. Any other value must be one of the stored ones.
  def with_stored_values(params, store)
    @custom_tool.stored_params.each do |param_def|
      name = param_def['source'].delete_prefix(Concerns::ToolStorable::STORED_SOURCE_PREFIX)
      values = store ? store.read(name) : []
      return [nil, missing_value_message(name)] if values.empty?

      passed = params[param_def['name'].to_sym].to_s.strip
      return [nil, "#{param_def['name']} must be one of: #{values.join(', ')}."] if passed.present? ? values.exclude?(passed) : values.many?

      params = params.merge(param_def['name'].to_sym => passed.presence || values.first)
    end
    [params, nil]
  end

  def missing_value_message(name)
    writers = @custom_tool.store_writers(name)
    next_step = writers.any? ? "Call #{writers.join(' or ')} first, then call this tool again." : 'Call the tool that looks it up first.'
    "No #{name} has been found for this customer yet. #{next_step}"
  end

  def record_response(tool_context, response_body)
    return unless @custom_tool.stores_values?

    state = tool_context.state
    store = tool_store(state, stored_verified_email(state))
    data = JSON.parse(response_body)
    @custom_tool.stores.each { |name, expression| store.write(name, Array.wrap(JMESPath.search(expression, data)).flatten.compact.map(&:to_s)) }
  end

  def tool_store(state, verified_email)
    conversation = find_conversation(state)
    namespace = @custom_tool.store_namespace
    Captain::ToolStore.new(conversation, namespace, verified_email) if conversation && namespace
  end
end
