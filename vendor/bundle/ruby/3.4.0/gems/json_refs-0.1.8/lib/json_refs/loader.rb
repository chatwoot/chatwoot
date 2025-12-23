require 'open-uri'
require 'json'
require 'yaml'

module JsonRefs
  class Loader
    class Json
      def call(file)
        JSON.load(file)
      end
    end

    class Yaml
      def call(file)
        RUBY_VERSION >= '3.1.0' ? YAML.unsafe_load(file) : YAML.load(file)
      end
    end

    EXTENSIONS = {
      'json' => JsonRefs::Loader::Json,
      'yaml' => JsonRefs::Loader::Yaml,
      'yml' => JsonRefs::Loader::Yaml,
    }.freeze

    def self.handle(filename)
      new.handle(filename)
    end

    def handle(filename)
      @body = read_reference_file(filename)
      ext = File.extname(filename)[1..-1]
      ext ||= 'json' if json?(@body)
      ext && EXTENSIONS.include?(ext) ? EXTENSIONS[ext].new.call(@body) : @body
    end

    def json?(file_body)
      JSON.load(file_body)
      true
    rescue JSON::ParserError => e
      false
    end

    private

    def read_reference_file(filename)
      if RUBY_VERSION >= '2.7.0'
        URI.open(filename, 'r', &:read)
      else
        open(filename, 'r', &:read)
      end
    end
  end
end
