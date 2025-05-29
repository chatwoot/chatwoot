module Enterprise::AsyncDispatcher
  def listeners
    super + [
      CaptainListener.instance
    ]
  end
end
