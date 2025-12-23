require 'fileutils'
require 'yaml'
require 'erb'

module Squasher
  class Config
    module Render
      extend self

      def process(path)
        @error = false
        # Support for Psych 4 (the default yaml parser for Ruby 3.1)
        opts = Gem::Version.new(Psych::VERSION).segments.first < 4 ? {} : { aliases: true }
        str = YAML.load(ERB.new(File.read(path)).result(binding), **opts)
        [str, @error]
      end

      def method_missing(*args)
        @error = true
        self
      end

      def const_missing(*args)
        @error = true
        self
      end

      def to_s
        ''
      end

      def inspect
        ''
      end
    end

    attr_reader :schema_file, :migration_version

    def initialize
      @root_path = Dir.pwd.freeze
      @migrations_folder = File.join(@root_path, 'db', 'migrate')
      @flags = []
      @databases = []
      set_app_path(@root_path)
    end

    def set(key, value)
      if key == :engine
        base = value.nil? ? @root_path : File.expand_path(value, @root_path)
        list = Dir.glob(File.join(base, '**', '*', 'config', 'application.rb'))
        case list.size
        when 1
          set_app_path(File.expand_path('../..', list.first))
        when 0
          Squasher.error(:cannot_find_dummy, base: base)
        else
          Squasher.error(:multi_dummy_case, base: base)
        end
      elsif key == :migration
        Squasher.error(:invalid_migration_version, value: value) unless value.to_s =~ /\A\d.\d\z/
        @migration_version = "[#{value}]"
      elsif key == :sql
        @schema_file = File.join(@app_path, 'db', 'structure.sql')
        @flags << key
      elsif key == :databases
        @databases = value
      else
        @flags << key
      end
    end

    def set?(k)
      @flags.include?(k)
    end

    def migration_files
      Dir.glob(File.join(migrations_folder, '**.rb'))
    end

    def migration_file(timestamp, migration_name)
      File.join(migrations_folder, "#{ timestamp }_#{ migration_name }.rb")
    end

    def migrations_folder?
      Dir.exist?(migrations_folder)
    end

    def dbconfig?
      !dbconfig.nil?
    end

    def stub_dbconfig
      return unless dbconfig?

      list = [dbconfig_file, schema_file]
      list.each do |file|
        next unless File.exist?(file)
        FileUtils.mv file, "#{ file }.sq"
      end

      File.open(dbconfig_file, 'wb') { |stream| stream.write dbconfig.to_yaml }

      yield

    ensure
      list.each do |file|
        next unless File.exist?("#{ file }.sq")
        FileUtils.mv "#{ file }.sq", file
      end
    end

    def in_app_root(&block)
      Dir.chdir(@app_path, &block)
    end

    private

    attr_reader :migrations_folder, :dbconfig_file

    def dbconfig
      return @dbconfig if defined?(@dbconfig)
      return @dbconfig = nil unless File.exist?(dbconfig_file)

      @dbconfig = nil

      begin
        content, soft_error = Render.process(dbconfig_file)
        if content.has_key?('development')
          @dbconfig = { 'development' => content['development'].merge('database' => 'squasher') }
          @databases&.each { |database| @dbconfig[database] = content[database] }
        end
      rescue
      end

      if soft_error && @dbconfig
        exit unless Squasher.ask(:use_dbconfig, config: @dbconfig.fetch('development'))
      end
      @dbconfig
    end

    def set_app_path(path)
      @app_path = path
      @schema_file = File.join(path, 'db', 'schema.rb')
      @dbconfig_file = File.join(path, 'config', 'database.yml')
    end
  end
end
