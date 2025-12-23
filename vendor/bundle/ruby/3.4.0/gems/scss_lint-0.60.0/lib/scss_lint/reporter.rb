module SCSSLint
  # Responsible for displaying lints to the user in some format.
  class Reporter
    attr_reader :lints, :files, :log

    def self.descendants
      ObjectSpace.each_object(Class).select { |klass| klass < self }
    end

    # @param lints [List<Lint>] a list of Lints sorted by file and line number
    # @param files [List<Hash>] a list of the files that were linted
    # @param logger [SCSSLint::Logger]
    def initialize(lints, files, logger)
      @lints = lints
      @files = files
      @log = logger
    end

    def report_lints
      raise NotImplementedError, 'You must implement report_lints'
    end
  end
end
