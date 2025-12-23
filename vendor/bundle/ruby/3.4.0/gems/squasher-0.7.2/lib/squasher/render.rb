require 'erb'

module Squasher
  class Render
    def self.render(*args)
      new(*args).render
    end

    attr_reader :name, :config

    def initialize(name, config)
      @name = name
      @config = config
    end

    def render
      ERB.new(template("#{ name }.rb"), nil, '-').result(binding)
    end

    def each_schema_line(&block)
      File.open(config.schema_file, 'r') do |stream|
        if @config.set?(:sql)
          stream_structure(stream, &block)
        else
          stream_schema(stream, &block)
        end
      end
    end

    private

    def stream_structure(stream)
      yield 'execute %q{'
      skip_mode = false
      ignored_table = ['ar_internal_metadata', 'schema_migrations']
      stream.each_line do |line|
        skip_mode = true if ignored_table.any? { |t| line.include?(t) }

        if skip_mode
          skip_mode = false if line.include?(';')
          next
        end

        yield line.gsub(/\A\s{,2}(.*)\s+\z/, '\1')
      end
      yield '}'
    end

    def stream_schema(stream)
      inside_schema = false

      stream.each_line do |raw_line|
        if inside_schema
          # reach the end of schema
          break if raw_line.index("end") == 0
          line = raw_line.gsub(/\A\s{,2}(.*)\s+\z/, '\1')
          if line.include?('create_table')
            line.gsub!(/(create_table.*),.* do/, '\1 do')
          end
          yield line
        else
          inside_schema = true if raw_line.include?("ActiveRecord::Schema")
        end
      end
    end

    def template(name)
      path = File.join(File.dirname(__FILE__), "templates/#{ name }.erb")
      template = File.open(path, "rb")
      content = template.read
      template.close
      content
    end
  end
end
