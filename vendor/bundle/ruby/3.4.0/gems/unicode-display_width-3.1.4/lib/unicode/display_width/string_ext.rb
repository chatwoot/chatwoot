# frozen_string_literal: true

require_relative "../display_width"

class String
  def display_width(ambiguous = nil, overwrite = nil, old_options = {}, **options)
    Unicode::DisplayWidth.of(self, ambiguous, overwrite, old_options = {}, **options)
  end
end
