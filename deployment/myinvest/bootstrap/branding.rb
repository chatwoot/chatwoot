# frozen_string_literal: true

require_relative 'lib/branding'

Myinvest::Branding.apply!
# rubocop:disable Rails/Output -- operational runner status is the interface.
puts 'MyInvest Support branding applied.'
# rubocop:enable Rails/Output
