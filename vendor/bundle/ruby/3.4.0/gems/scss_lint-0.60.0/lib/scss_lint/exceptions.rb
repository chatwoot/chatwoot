module SCSSLint::Exceptions
  # Raised when an invalid flag is given via the command line.
  class InvalidCLIOption < StandardError; end

  # Raised when the configuration file is invalid for some reason.
  class InvalidConfiguration < StandardError; end

  # Raised when an unexpected error occurs in a linter
  class LinterError < StandardError; end

  # Raised when no files were specified or specified glob patterns did not match
  # any files.
  class NoFilesError < StandardError; end

  # Raised when a required library (specified via command line) does not exist.
  class RequiredLibraryMissingError < StandardError; end

  # Raised when a linter gem plugin is required but not installed.
  class PluginGemLoadError < StandardError; end

  # Raised when the preprocessor tool exits with a non-zero code.
  class PreprocessorError < StandardError; end
end
