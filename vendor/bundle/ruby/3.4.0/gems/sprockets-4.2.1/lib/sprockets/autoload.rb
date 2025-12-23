# frozen_string_literal: true
module Sprockets
  module Autoload
    autoload :Babel, 'sprockets/autoload/babel'
    autoload :Closure, 'sprockets/autoload/closure'
    autoload :CoffeeScript, 'sprockets/autoload/coffee_script'
    autoload :Eco, 'sprockets/autoload/eco'
    autoload :EJS, 'sprockets/autoload/ejs'
    autoload :JSMinC, 'sprockets/autoload/jsminc'
    autoload :Sass, 'sprockets/autoload/sass'
    autoload :SassC, 'sprockets/autoload/sassc'
    autoload :Uglifier, 'sprockets/autoload/uglifier'
    autoload :YUI, 'sprockets/autoload/yui'
    autoload :Zopfli, 'sprockets/autoload/zopfli'
  end
end
