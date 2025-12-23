module Regexp::Expression
  module Shared
    # default implementation
    def parts
      [text.dup]
    end

    private

    def intersperse(expressions, separator)
      expressions.flat_map { |exp| [exp, separator] }.slice(0...-1)
    end
  end

  CharacterSet.class_eval            { def parts; ["#{text}#{'^' if negated?}", *expressions, ']']        end }
  CharacterSet::Range.class_eval     { def parts; intersperse(expressions, text.dup)                      end }
  Conditional::Expression.class_eval { def parts; [text.dup, condition, *intersperse(branches, '|'), ')'] end }
  Group::Base.class_eval             { def parts; [text.dup, *expressions, ')']                           end }
  Group::Passive.class_eval          { def parts; implicit? ? expressions : super                         end }
  Group::Comment.class_eval          { def parts; [text.dup]                                              end }
  Subexpression.class_eval           { def parts; expressions                                             end }
  SequenceOperation.class_eval       { def parts; intersperse(expressions, text.dup)                      end }
end
