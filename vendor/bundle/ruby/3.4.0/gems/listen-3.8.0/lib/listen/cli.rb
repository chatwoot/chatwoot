# frozen_string_literal: true

require 'thor'
require 'listen'
require 'logger'

module Listen
  class CLI < Thor
    default_task :start

    desc 'start', 'Starts Listen'

    class_option :verbose,
                 type:    :boolean,
                 default: false,
                 aliases: '-v',
                 banner:  'Verbose'

    class_option :directory,
                 type:    :array,
                 default: ['.'],
                 aliases: '-d',
                 banner:  'One or more directories to listen to'

    class_option :relative,
                 type:    :boolean,
                 default: false,
                 aliases: '-r',
                 banner:  'Convert paths relative to current directory'

    def start
      Listen::Forwarder.new(options).start
    end
  end

  class Forwarder
    attr_reader :logger

    def initialize(options)
      @options = options
      @logger = ::Logger.new(STDOUT, level: ::Logger::INFO)
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

      listener = Listen.to(*directory, relative: relative, &callback)

      listener.start

      sleep 0.5 while listener.processing?
    end
  end
end
