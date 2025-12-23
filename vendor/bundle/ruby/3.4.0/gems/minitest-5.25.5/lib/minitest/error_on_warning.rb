module Minitest

  module ErrorOnWarning # :nodoc:
    def warn message, category: nil
      message = "[#{category}] #{message}" if category
      raise UnexpectedWarning, message
    end
  end

  ::Warning.singleton_class.prepend ErrorOnWarning
end
