# frozen_string_literal: true

# This writes the prism ripper translation into the Ripper constant so that
# users can transparently use Ripper without any changes.
Ripper = Prism::Translation::Ripper
