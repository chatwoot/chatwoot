# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Checks that left braces for adjacent single line lets are aligned.
      #
      # @example
      #   # bad
      #   let(:foobar) { blahblah }
      #   let(:baz) { bar }
      #   let(:a) { b }
      #
      #   # good
      #   let(:foobar) { blahblah }
      #   let(:baz)    { bar }
      #   let(:a)      { b }
      #
      class AlignLeftLetBrace < Base
        extend AutoCorrector

        MSG = 'Align left let brace'

        def self.autocorrect_incompatible_with
          [Layout::ExtraSpacing]
        end

        def on_new_investigation
          super
          return if processed_source.blank?

          token_aligner.offending_tokens.each do |let|
            add_offense(let.loc.begin) do |corrector|
              corrector.insert_before(
                let.loc.begin, token_aligner.indent_for(let)
              )
            end
          end
        end

        private

        def token_aligner
          RuboCop::RSpec::AlignLetBrace.new(processed_source.ast, :begin)
        end
      end
    end
  end
end
