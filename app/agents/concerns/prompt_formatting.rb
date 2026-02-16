# frozen_string_literal: true

# Shared prompt formatting helpers for agents that build structured system prompts
module PromptFormatting
  extend ActiveSupport::Concern

  private

  # Format a section header for system prompt sections
  def section_header(title)
    separator = '=' * 24
    underline = '=' * title.length
    "#{separator}\n#{title}\n#{underline}"
  end
end
