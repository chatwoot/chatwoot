require 'erb'

class Brakeman::Report
  class Renderer
    def initialize(template_file, hash = {})
      hash[:locals] ||= {}
      singleton = class << self; self end

      hash[:locals].each do |attribute_name, attribute_value|
        singleton.send(:define_method, attribute_name) { attribute_value }
      end

      # There are last, so as to make overwriting these using locals impossible.
      singleton.send(:define_method, 'template_file') { template_file }
      singleton.send(:define_method, 'template') {
        File.read(File.expand_path("templates/#{template_file}.html.erb", File.dirname(__FILE__)))
      }
    end

    def render
      ERB.new(template).result(binding)
    end
  end
end