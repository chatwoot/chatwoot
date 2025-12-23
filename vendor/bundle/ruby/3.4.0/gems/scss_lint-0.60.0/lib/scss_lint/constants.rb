# frozen_string_literal: true

# Global application constants.
module SCSSLint
  SCSS_LINT_HOME = File.realpath(File.join(File.dirname(__FILE__), '..', '..')).freeze
  SCSS_LINT_DATA = File.join(SCSS_LINT_HOME, 'data').freeze

  REPO_URL = 'https://github.com/sds/scss-lint'.freeze
  BUG_REPORT_URL = "#{REPO_URL}/issues".freeze
end
