# frozen_string_literal: true
require_relative 'template'
require 'rdiscount'

aliases = {
  :escape_html => :filter_html,
  :smartypants => :smart
}.freeze

_flags = [:smart, :filter_html, :smartypants, :escape_html].freeze

# Discount Markdown implementation. See:
# http://github.com/rtomayko/rdiscount
#
# RDiscount is a simple text filter. It does not support +scope+ or
# +locals+. The +:smart+ and +:filter_html+ options may be set true
# to enable those flags on the underlying RDiscount object.
Tilt::RDiscountTemplate = Tilt::StaticTemplate.subclass do
  flags = _flags.select { |flag| @options[flag] }.
    map! { |flag| aliases[flag] || flag }

  RDiscount.new(@data, *flags).to_html
end
