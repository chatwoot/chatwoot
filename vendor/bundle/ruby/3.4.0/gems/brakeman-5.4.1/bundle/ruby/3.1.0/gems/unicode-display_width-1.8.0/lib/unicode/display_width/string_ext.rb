require_relative '../display_width' unless defined? Unicode::DisplayWidth

class String
  def display_width(ambiguous = 1, overwrite = {}, options = {})
    Unicode::DisplayWidth.of(self, ambiguous, overwrite, options)
  end

  def display_size(*args)
    warn "Deprecation warning: Please use `String#display_width` instead of `String#display_size`"
    display_width(*args)
  end

  def display_length(*args)
    warn "Deprecation warning: Please use `String#display_width` instead of `String#display_length`"
    display_width(*args)
  end
end
