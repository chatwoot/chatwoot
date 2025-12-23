module SafeYAML
  class SafeToRubyVisitor < Psych::Visitors::ToRuby
    INITIALIZE_ARITY = superclass.instance_method(:initialize).arity

    def initialize(resolver)
      case INITIALIZE_ARITY
      when 2
        # https://github.com/tenderlove/psych/blob/v2.0.0/lib/psych/visitors/to_ruby.rb#L14-L28
        loader  = Psych::ClassLoader.new
        scanner = Psych::ScalarScanner.new(loader)
        super(scanner, loader)

      else
        super()
      end

      @resolver = resolver
    end

    def accept(node)
      if node.tag
        SafeYAML.tag_safety_check!(node.tag, @resolver.options)
        return super
      end

      @resolver.resolve_node(node)
    end
  end
end
