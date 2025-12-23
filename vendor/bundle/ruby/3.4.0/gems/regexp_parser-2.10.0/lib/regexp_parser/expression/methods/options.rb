module Regexp::Expression
  class Base
    def multiline?
      options[:m] == true
    end
    alias :m? :multiline?

    def case_insensitive?
      options[:i] == true
    end
    alias :i? :case_insensitive?
    alias :ignore_case? :case_insensitive?

    def free_spacing?
      options[:x] == true
    end
    alias :x? :free_spacing?
    alias :extended? :free_spacing?

    def default_classes?
      options[:d] == true
    end
    alias :d? :default_classes?

    def ascii_classes?
      options[:a] == true
    end
    alias :a? :ascii_classes?

    def unicode_classes?
      options[:u] == true
    end
    alias :u? :unicode_classes?
  end
end
