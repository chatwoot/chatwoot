# frozen_string_literal: true

module RuboCop
  module Cop
    module Legacy
      # Legacy support for Corrector#corrections
      # See https://docs.rubocop.org/rubocop/v1_upgrade_notes.html
      class CorrectionsProxy
        def initialize(corrector)
          @corrector = corrector
        end

        def <<(callable)
          suppress_clobbering { @corrector.transaction { callable.call(@corrector) } }
        end

        def empty?
          @corrector.empty?
        end

        def concat(corrections)
          if corrections.is_a?(CorrectionsProxy)
            suppress_clobbering { corrector.merge!(corrections.corrector) }
          else
            corrections.each { |correction| self << correction }
          end
        end

        protected

        attr_reader :corrector

        private

        def suppress_clobbering
          yield
        rescue ::Parser::ClobberingError
          # ignore Clobbering errors
        end
      end
    end
  end
end
