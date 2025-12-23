# The Slim module contains all Slim related classes (e.g. Engine, Parser).
# Plugins might also reside within the Slim module (e.g. Include, Smart).
# @api public
module Slim
  # Slim engine which transforms slim code to executable ruby code
  # @api public
  class Engine < Temple::Engine
    # This overwrites some Temple default options or sets default options for Slim specific filters.
    # It is recommended to set the default settings only once in the code and avoid duplication. Only use
    # `define_options` when you have to override some default settings.
    define_options pretty: false,
                   sort_attrs: true,
                   format: :xhtml,
                   attr_quote: '"',
                   merge_attrs: {'class' => ' '},
                   generator: Temple::Generators::StringBuffer,
                   default_tag: 'div'

    filter :Encoding
    filter :RemoveBOM
    use Slim::Parser
    use Slim::Embedded
    use Slim::Interpolation
    use Slim::Splat::Filter
    use Slim::DoInserter
    use Slim::EndInserter
    use Slim::Controls
    html :AttributeSorter
    html :AttributeMerger
    use Slim::CodeAttributes
    use(:AttributeRemover) { Temple::HTML::AttributeRemover.new(remove_empty_attrs: options[:merge_attrs].keys) }
    html :Pretty
    filter :Escapable
    filter :ControlFlow
    filter :MultiFlattener
    filter :StaticMerger
    use(:Generator) { options[:generator] }
  end
end
