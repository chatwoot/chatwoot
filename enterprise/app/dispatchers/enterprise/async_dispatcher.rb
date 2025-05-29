module Enterprise::AsyncDispatcher
  def listeners
    super + [
      AiagentListener.instance
    ]
  end
end
