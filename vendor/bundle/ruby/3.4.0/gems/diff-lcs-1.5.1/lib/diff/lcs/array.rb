# frozen_string_literal: true

require "diff/lcs"

class Array
  include Diff::LCS
end
