# Values that the tools of one toolset found for the verified customer of a conversation. Only Chatwoot writes them,
# from tool responses. Each value records the email it was found for, so verifying another email makes it unreadable.
class Captain::ToolStore
  # Enough for a customer's own records. The values are listed to the model when it passes a wrong one.
  MAX_VALUES = 20

  pattr_initialize :conversation, :namespace, :verified_email

  # A new result replaces the earlier one, so two lookups never mix the records of two customers
  def write(name, values)
    ::Redis::Alfred.setex(key(name), { email: verified_email, values: values.first(MAX_VALUES) }.to_json, Captain::EmailVerification::VERIFIED_TTL)
  end

  def read(name)
    stored = ::Redis::Alfred.get(key(name))
    return [] if stored.blank?

    data = JSON.parse(stored)
    data['email'] == verified_email ? data['values'] : []
  end

  private

  def key(name)
    format(::Redis::RedisKeys::CAPTAIN_TOOL_STORE, conversation_id: conversation.id, namespace: namespace, name: name)
  end
end
