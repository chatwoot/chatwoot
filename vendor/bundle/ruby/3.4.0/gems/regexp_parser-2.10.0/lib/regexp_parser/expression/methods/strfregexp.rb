module Regexp::Expression
  class Base

    #   %l  Level (depth) of the expression. Returns 'root' for the root
    #       expression, returns zero or higher for all others.
    #
    #   %>  Indentation at expression's level.
    #
    #   %x  Index of the expression at its depth. Available when using
    #       the sprintf_tree method only.
    #
    #   %s  Start offset within the whole expression.
    #   %e  End offset within the whole expression.
    #   %S  Length of expression.
    #
    #   %o  Coded offset and length, same as '@%s+%S'
    #
    #   %y  Type of expression.
    #   %k  Token of expression.
    #   %i  ID, same as '%y:%k'
    #   %c  Class name
    #
    #   %q  Quantifier info, as {m[,M]}
    #   %Q  Quantifier text
    #
    #   %z  Quantifier min
    #   %Z  Quantifier max
    #
    #   %t  Base text of the expression (excludes quantifier, if any)
    #   %~t Full text if the expression is terminal, otherwise %i
    #   %T  Full text of the expression (includes quantifier, if any)
    #
    #   %b  Basic info, same as '%o %i'
    #   %m  Most info, same as '%b %q'
    #   %a  All info, same as '%m %t'
    #
    def strfregexp(format = '%a', indent_offset = 0, index = nil)
      have_index    = index ? true : false

      part = {}

      print_level = nesting_level > 0 ? nesting_level - 1 : nil

      # Order is important! Fields that use other fields in their
      # definition must appear before the fields they use.
      part_keys = %w[a m b o i l x s e S y k c q Q z Z t ~t T >]
      part.keys.each {|k| part[k] = "<?#{k}?>"}

      part['>'] = print_level ? ('  ' * (print_level + indent_offset)) : ''

      part['l'] = print_level ? "#{'%d' % print_level}" : 'root'
      part['x'] = "#{'%d' % index}" if have_index

      part['s'] = starts_at
      part['S'] = full_length
      part['e'] = starts_at + full_length
      part['o'] = coded_offset

      part['k'] = token
      part['y'] = type
      part['i'] = '%y:%k'
      part['c'] = self.class.name

      if quantified?
        if quantifier.max == -1
          part['q'] = "{#{quantifier.min}, or-more}"
        else
          part['q'] = "{#{quantifier.min}, #{quantifier.max}}"
        end

        part['Q'] = quantifier.text
        part['z'] = quantifier.min
        part['Z'] = quantifier.max
      else
        part['q'] = '{1}'
        part['Q'] = ''
        part['z'] = '1'
        part['Z'] = '1'
      end

      part['t'] = to_s(:base)
      part['~t'] = terminal? ? to_s : "#{type}:#{token}"
      part['T'] = to_s(:full)

      part['b'] = '%o %i'
      part['m'] = '%b %q'
      part['a'] = '%m %t'

      out = format.dup

      part_keys.each do |k|
        out.gsub!(/%#{k}/, part[k].to_s)
      end

      out
    end

    alias :strfre :strfregexp
  end

  class Subexpression < Regexp::Expression::Base
    def strfregexp_tree(format = '%a', include_self = true, separator = "\n")
      output = include_self ? [self.strfregexp(format)] : []

      output += flat_map do |exp, index|
        exp.strfregexp(format, (include_self ? 1 : 0), index)
      end

      output.join(separator)
    end

    alias :strfre_tree :strfregexp_tree
  end
end
