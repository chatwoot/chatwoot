# frozen_string_literal: true

require_relative "command_processor"

module Byebug
  #
  # Processes commands in post_mortem mode
  #
  class PostMortemProcessor < CommandProcessor
    def commands
      super.select(&:allow_in_post_mortem)
    end

    def prompt
      "(byebug:post_mortem) "
    end
  end
end
