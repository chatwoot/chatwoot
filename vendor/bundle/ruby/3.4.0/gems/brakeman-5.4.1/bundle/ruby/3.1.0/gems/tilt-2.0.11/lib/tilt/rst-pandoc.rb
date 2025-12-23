require 'tilt/template'
require 'pandoc'

module Tilt
  # Pandoc reStructuredText implementation. See:
  # http://pandoc.org/
  class RstPandocTemplate < PandocTemplate
    self.default_mime_type = 'text/html'

    def prepare
      @engine = PandocRuby.new(data, :f => "rst")
      @output = nil
    end

    def evaluate(scope, locals, &block)
      @output ||= @engine.to_html.strip
    end

    def allows_script?
      false
    end
  end
end
