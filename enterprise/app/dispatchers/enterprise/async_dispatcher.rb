module Enterprise::AsyncDispatcher
  def listeners
    super + [
      CaptainListener.instance,
      Captain::ReportingEventListener.instance
    ]
  end
end
