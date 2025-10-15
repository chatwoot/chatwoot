# lib/error_logger.rb
module ErrorLogger
  def error(exception = nil, **kwargs, &block)
    if exception.is_a?(Exception)
      # Always include full_message with backtrace
      super(exception.full_message(highlight: false, order: :top), **kwargs, &block)
    else
      super(exception, **kwargs, &block)
    end
  end
end
