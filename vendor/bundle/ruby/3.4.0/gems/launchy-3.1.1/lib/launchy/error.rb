# frozen_string_literal: true

module Launchy
  class Error < ::StandardError; end
  class ApplicationNotFoundError < Error; end
  class CommandNotFoundError < Error; end
  class ArgumentError < Error; end
end
