module IndividualReadStateBroadcasting
  private

  def broadcast(account, tokens, event_name, data, conversation: nil)
    return if tokens.blank?

    if conversation && account.feature_enabled?(Conversations::ReadStateService::FEATURE_FLAG)
      payloads = Conversations::ReadStateBroadcast.new(conversation: conversation).payloads(tokens, data, nested: data.key?(:conversation))
      return payloads.each { |recipients, payload| broadcast(account, recipients, event_name, payload) }
    end

    payload = data.merge(account_id: account.id)
    payload[:performer] = Current.user.push_event_data if Current.user.present?
    ::ActionCableBroadcastJob.perform_later(tokens.uniq, event_name, payload)
  end
end
