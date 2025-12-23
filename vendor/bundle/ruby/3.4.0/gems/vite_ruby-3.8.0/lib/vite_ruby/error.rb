# frozen_string_literal: true

# Internal: Provides common functionality for errors.
class ViteRuby::Error < StandardError
  def message
    super.sub(':troubleshooting:', <<~MSG)
      Visit the Troubleshooting guide for more information:
        https://vite-ruby.netlify.app/guide/troubleshooting.html#troubleshooting
    MSG
  end
end
