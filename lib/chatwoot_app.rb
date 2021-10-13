# frozen_string_literal: true

require 'pathname'

module ChatwootApp
  def self.root
    Pathname.new(File.expand_path('..', __dir__))
  end

  def self.max_limit
    100_000
  end

  def self.ee?
    # Disable EE using environment variables when testing
    return if ENV.fetch('DISABLE_EE', false)

    @ee ||= root.join('ee').exist?
  end

  def self.custom?
    @custom ||= root.join('custom').exist?
  end

  def self.extensions
    if custom?
      %w[ee custom]
    elsif ee?
      %w[ee]
    else
      %w[]
    end
  end
end
