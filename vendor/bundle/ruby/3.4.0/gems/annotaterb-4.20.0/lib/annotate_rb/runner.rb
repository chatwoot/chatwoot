# frozen_string_literal: true

module AnnotateRb
  class Runner
    class << self
      attr_reader :runner

      def run(args)
        self.runner = new

        runner.run(args)

        self.runner = nil
      end

      def running?
        !!runner
      end

      private

      attr_writer :runner
    end

    def run(args)
      config_file_options = ConfigLoader.load_config
      parser = Parser.new(args, {})

      parsed_options = parser.parse
      remaining_args = parser.remaining_args

      options = config_file_options.merge(parsed_options)

      @options = Options.from(options, {working_args: remaining_args})
      AnnotateRb::RakeBootstrapper.call(@options)

      if @options[:command]
        @options[:command].call(@options)
      else
        # TODO
        raise "Didn't specify a command"
      end
    end
  end
end
