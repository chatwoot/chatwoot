module SCSSLint
  # Reports a single line for each clean file (having zero lints).
  class Reporter::CleanFilesReporter < Reporter
    def report_lints
      dirty_files = lints.map(&:filename).uniq
      clean_files = files.map { |e| e['path'] } - dirty_files
      clean_files.sort.join("\n") + "\n" if clean_files.any?
    end
  end
end
