module Feature
  module ClassMethods
    def feature
    end
  end

  # in uber, this would look somehow like
  # module Feature
  #   module ClassMethods ... end

  #   extend Uber::InheritableIncluded
  #   inheritable_included do |includer|
  #     includer.extend ClassMethods
  #   end
  # end

  InheritedIncludedCodeBlock = lambda do |includer|
    includer.extend ClassMethods
  end

  module RecursiveIncluded
    def included(includer)
      #super # TODO: test me.
      puts "RecursiveIncluded in #{includer}"

      includer.module_eval do
        InheritedIncludedCodeBlock.call(includer)
        extend RecursiveIncluded
      end
    end
  end
  extend RecursiveIncluded
end

module Client
  include Feature
end

module Extension
  include Client
end

module Plugin
  include Extension
end

module Framework
  include Plugin
end

Client.feature
Extension.feature
Plugin.feature
Framework.feature