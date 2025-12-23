# frozen_string_literal: true

module Process
  class << self
    def fork_with_simplecov(&block)
      if defined?(SimpleCov) && SimpleCov.running
        fork_without_simplecov do
          SimpleCov.at_fork.call(Process.pid)
          block.call if block_given?
        end
      else
        fork_without_simplecov(&block)
      end
    end

    alias fork_without_simplecov fork
    alias fork fork_with_simplecov
  end
end
