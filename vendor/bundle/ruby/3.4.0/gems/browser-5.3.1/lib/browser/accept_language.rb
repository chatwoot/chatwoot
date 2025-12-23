# frozen_string_literal: true

module Browser
  class AcceptLanguage
    def self.languages
      @languages ||= YAML.load_file(Browser.root.join("languages.yml"))
    end

    def self.parse(accept_language)
      return [] unless accept_language

      accept_language
        .split(",")
        .map {|string| string.squeeze(" ").strip }
        .map {|part| new(part) }
        .reject {|al| al.quality.zero? }
        .sort_by.with_index {|al, idx| [-al.quality, idx] }
    end

    attr_reader :part

    def initialize(part)
      @part = part
    end

    def full
      @full ||= [code, region].compact.join("-")
    end

    def name
      self.class.languages[full] || self.class.languages[code]
    end

    def code
      @code ||= begin
        code = part[/\A([^-;]+)/, 1]
        code&.downcase
      end
    end

    def region
      @region ||= begin
        region = part[/\A(?:.*?)-([^;-]+)/, 1]
        region&.upcase
      end
    end

    def quality
      @quality ||= begin
        Float(quality_value || 1.0)
      rescue ArgumentError
        0.1
      end
    end

    private def quality_value
      qvalue = part[/;q=([\d.]+)/, 1]
      qvalue = /\A0\.0?\z/.match?(qvalue) ? "0.0" : qvalue
      qvalue = qvalue.squeeze(".") if qvalue
      qvalue
    end
  end
end
