# frozen_string_literal: true

require 'pathname'

module ChatwootApp
  def self.root
    Pathname.new(File.expand_path('..', __dir__))
  end

  def self.max_limit
    100_000
  end

  def self.enterprise?
    # Disable EE using environment variables when testing
    return if ENV.fetch('DISABLE_EE', false)

    @enterprise ||= root.join('enterprise').exist?
  end

  def self.custom?
    @custom ||= root.join('custom').exist?
  end

  def self.extensions
    if custom?
      %w[enterprise custom]
    elsif enterprise?
      %w[enterprise]
    else
      %w[]
    end
  end
end
