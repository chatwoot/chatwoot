# frozen_string_literal: true

require 'diff/lcs'

module RSpec
  module Support
    module Spec
      module DiffHelpers
        # In the updated version of diff-lcs several diff headers change format slightly
        # compensate for this and change minimum version in RSpec 4
        if ::Diff::LCS::VERSION.to_f < 1.4
          def one_line_header(line_number=2)
            "-1,#{line_number} +1,#{line_number}"
          end
        else
          def one_line_header(_=2)
            "-1 +1"
          end
        end

        if Diff::LCS::VERSION.to_f < 1.4 || Diff::LCS::VERSION >= "1.4.4"
          def removing_two_line_header
            "-1,3 +1"
          end
        else
          def removing_two_line_header
            "-1,3 +1,5"
          end
        end
      end
    end
  end
end
