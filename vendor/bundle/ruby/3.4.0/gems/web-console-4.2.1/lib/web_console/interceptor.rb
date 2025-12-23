module WebConsole
  module Interceptor
    def self.call(request, error)
      backtrace_cleaner = request.get_header("action_dispatch.backtrace_cleaner")

      # Get the original exception if ExceptionWrapper decides to follow it.
      Thread.current[:__web_console_exception] = error

      # ActionView::Template::Error bypass ExceptionWrapper original
      # exception following. The backtrace in the view is generated from
      # reaching out to original_exception in the view.
      if error.is_a?(ActionView::Template::Error)
        Thread.current[:__web_console_exception] = error.cause
      end
    end
  end
end
