# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # Repacks Parser's diagnostics/errors
      # into RuboCop's offenses.
      class Syntax < Base
        LEVELS = %i[error fatal].freeze

        def on_other_file
          add_offense_from_error(processed_source.parser_error) if processed_source.parser_error
          syntax_errors = processed_source.diagnostics.select { |d| LEVELS.include?(d.level) }
          syntax_errors.each do |diagnostic|
            add_offense_from_diagnostic(diagnostic, processed_source.ruby_version)
          end
          super
        end

        private

        def add_offense_from_diagnostic(diagnostic, ruby_version)
          message = if LSP.enabled?
                      diagnostic.message
                    else
                      "#{diagnostic.message}\n(Using Ruby #{ruby_version} parser; " \
                        'configure using `TargetRubyVersion` parameter, under `AllCops`)'
                    end
          add_offense(diagnostic.location, message: message, severity: diagnostic.level)
        end

        def add_offense_from_error(error)
          message = beautify_message(error.message)
          add_global_offense(message, severity: :fatal)
        end

        def beautify_message(message)
          message = message.capitalize
          message << '.' unless message.end_with?('.')
          message
        end

        def find_severity(_range, _severity)
          :fatal
        end
      end
    end
  end
end
