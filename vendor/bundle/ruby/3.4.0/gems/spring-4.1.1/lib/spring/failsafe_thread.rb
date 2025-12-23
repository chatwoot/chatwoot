require 'thread'

module Spring
  class << self
    def failsafe_thread
      Thread.new {
        begin
          yield
        rescue
        end
      }
    end
  end
end
