module SCSSLint
  # Reports a single line per file.
  class Reporter::FilesReporter < Reporter
    def report_lints
      lints.map(&:filename).uniq.join("\n") + "\n" if lints.any?
    end
  end
end
