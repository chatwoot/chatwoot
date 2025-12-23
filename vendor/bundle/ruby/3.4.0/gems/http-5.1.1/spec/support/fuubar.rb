# frozen_string_literal: true

require "fuubar"

RSpec.configure do |config|
  # Use Fuubar instafail-alike formatter, unless a formatter has already been
  # configured (e.g. via a command-line flag).
  config.default_formatter = "Fuubar"

  # Disable auto-refresh of the fuubar progress bar to avoid surprises during
  # debugiing. And simply because there's next to absolutely no point in having
  # this turned on.
  #
  # > By default fuubar will automatically refresh the bar (and therefore
  # > the ETA) every second. Unfortunately this doesn't play well with things
  # > like debuggers. When you're debugging, having a bar show up every second
  # > is undesireable.
  #
  # See: https://github.com/thekompanee/fuubar#disabling-auto-refresh
  config.fuubar_auto_refresh = false
end
