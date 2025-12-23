# frozen_string_literal: true

module RuboCop
  module Cop
    module Legacy
      # Legacy Corrector for v0 API support.
      # See https://docs.rubocop.org/rubocop/v1_upgrade_notes.html
      class Corrector < RuboCop::Cop::Corrector
        # Support legacy second argument
        def initialize(source, corr = [])
          super(source)
          if corr.is_a?(CorrectionsProxy)
            merge!(corr.send(:corrector))
          else
            unless corr.empty?
              warn Rainbow(<<~WARNING).yellow, uplevel: 1
                `Corrector.new` with corrections is deprecated.
                See https://docs.rubocop.org/rubocop/v1_upgrade_notes.html
              WARNING
            end

            corr.each { |c| corrections << c }
          end
        end

        def corrections
          warn Rainbow(<<~WARNING).yellow, uplevel: 1
            `Corrector#corrections` is deprecated. Open an issue if you have a valid usecase.
            See https://docs.rubocop.org/rubocop/v1_upgrade_notes.html
          WARNING

          CorrectionsProxy.new(self)
        end
      end
    end
  end
end
