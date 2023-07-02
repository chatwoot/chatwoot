class Messages::Internal::MessageBuilder
  extends Messages::MessageBuilder

  def perform
    super

    @message
  end
end
