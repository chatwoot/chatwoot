# frozen_string_literal: true

module RuboCop
  module LSP
    # Severity for Language Server Protocol of RuboCop.
    # @api private
    class Severity
      SEVERITIES = {
        fatal: LanguageServer::Protocol::Constant::DiagnosticSeverity::ERROR,
        error: LanguageServer::Protocol::Constant::DiagnosticSeverity::ERROR,
        warning: LanguageServer::Protocol::Constant::DiagnosticSeverity::WARNING,
        convention: LanguageServer::Protocol::Constant::DiagnosticSeverity::INFORMATION,
        refactor: LanguageServer::Protocol::Constant::DiagnosticSeverity::HINT,
        info: LanguageServer::Protocol::Constant::DiagnosticSeverity::HINT
      }.freeze

      def self.find_by(rubocop_severity)
        if (severity = SEVERITIES[rubocop_severity.to_sym])
          return severity
        end

        Logger.log("Unknown severity: #{rubocop_severity}")
        LanguageServer::Protocol::Constant::DiagnosticSeverity::HINT
      end
    end
  end
end
