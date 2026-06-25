module Enterprise::Messages::MessageBuilder
  private

  def message_type
    return @message_type if @message_type == 'incoming' && voice_call_inbox? && @params[:content_type] == 'voice_call'

    super
  end

  def voice_call_inbox?
    @conversation.inbox.channel.try(:voice_enabled?)
  end
end
