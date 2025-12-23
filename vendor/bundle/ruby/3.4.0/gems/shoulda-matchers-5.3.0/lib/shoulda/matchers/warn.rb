module Shoulda
  module Matchers
    # @private
    TERMINAL_MAX_WIDTH = 72

    # @private
    def self.warn(message)
      header = 'Warning from shoulda-matchers:'
      divider = '*' * TERMINAL_MAX_WIDTH
      wrapped_message = word_wrap(message)
      full_message = [
        divider,
        [header, wrapped_message.strip].join("\n\n"),
        divider,
      ].join("\n")

      Kernel.warn(full_message)
    end

    # @private
    def self.warn_about_deprecated_method(old_method, new_method)
      warn <<EOT
#{old_method} is deprecated and will be removed in the next major
release. Please use #{new_method} instead.
EOT
    end
  end
end
