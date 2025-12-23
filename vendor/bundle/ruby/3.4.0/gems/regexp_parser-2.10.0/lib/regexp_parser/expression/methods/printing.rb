module Regexp::Expression
  module Shared
    def inspect
      [
        "#<#{self.class}",
        pretty_print_instance_variables.map { |v| " #{v}=#{instance_variable_get(v).inspect}" },
        ">"
      ].join
    end

    # Make pretty-print work despite #inspect implementation.
    def pretty_print(q)
      q.pp_object(self)
    end

    # Called by pretty_print (ruby/pp) and #inspect.
    def pretty_print_instance_variables
      [
        (:@text unless text.to_s.empty?),
        (:@quantifier if quantified?),
        (:@options unless options.empty?),
        (:@expressions unless terminal?),
      ].compact
    end
  end
end
