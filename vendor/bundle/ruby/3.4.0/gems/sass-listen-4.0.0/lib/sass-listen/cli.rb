require 'thor'
require 'sass-listen'
require 'logger'

module SassListen
  class CLI < Thor
    default_task :start

    desc 'start', 'Starts SassListen'

    class_option :verbose,
                 type:    :boolean,
                 default: false,
                 aliases: '-v',
                 banner:  'Verbose'

    class_option :directory,
                 type:    :array,
                 default: '.',
                 aliases: '-d',
                 banner:  'The directory to listen to'

    class_option :relative,
                 type:    :boolean,
                 default: false,
                 aliases: '-r',
                 banner:  'Convert paths relative to current directory'

    def start
      SassListen::Forwarder.new(options).start
    end
  end

  class Forwarder
    attr_reader :logger
    def initialize(options)
      @options = options
      @logger = ::Logger.new(STDOUT)
      @logger.level = ::Logger::INFO
      @logger.formatter = proc { |_, _, _, msg| "#{msg}\n" }
    end

    def start
      logger.info 'Starting listen...'
      directory = @options[:directory]
      relative = @options[:relative]
      callback = proc do |modified, added, removed|
        if @options[:verbose]
          logger.info "+ #{added}" unless added.empty?
          logger.info "- #{removed}" unless removed.empty?
          logger.info "> #{modified}" unless modified.empty?
        end
      end

      listener = SassListen.to(
        directory,
        relative: relative,
        &callback)

      listener.start

      sleep 0.5 while listener.processing?
    end
  end
end
