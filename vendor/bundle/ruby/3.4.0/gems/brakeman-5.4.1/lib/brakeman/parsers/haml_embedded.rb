module Brakeman
  module FakeHamlFilter
    # Copied from Haml 4 - force delayed compilation
    def compile(compiler, text)
      filter = self
      compiler.instance_eval do
        text = unescape_interpolation(text).gsub(/(\\+)n/) do |s|
          escapes = $1.size
          next s if escapes % 2 == 0
          ("\\" * (escapes - 1)) + "\n"
        end
        # We need to add a newline at the beginning to get the
        # filter lines to line up (since the Haml filter contains
        # a line that doesn't show up in the source, namely the
        # filter name). Then we need to escape the trailing
        # newline so that the whole filter block doesn't take up
        # too many.
        text = "\n" + text.sub(/\n"\Z/, "\\n\"")
        push_script <<RUBY.rstrip, :escape_html => false
find_and_preserve(#{filter.inspect}.render_with_options(#{text}, _hamlout.options))
RUBY
        return
      end
    end
  end
end

# Fake CoffeeScript filter for Haml
module Haml::Filters::Coffee
  include Haml::Filters::Base
  extend Brakeman::FakeHamlFilter
end

# Fake Markdown filter for Haml
module Haml::Filters::Markdown
  include Haml::Filters::Base
  extend Brakeman::FakeHamlFilter
end

# Fake Sass filter for Haml
module Haml::Filters::Sass
  include Haml::Filters::Base
  extend Brakeman::FakeHamlFilter
end
