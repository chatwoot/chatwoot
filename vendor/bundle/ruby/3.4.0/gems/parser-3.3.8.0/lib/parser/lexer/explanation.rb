# frozen_string_literal: true

module Parser

  module Lexer::Explanation

    def self.included(klass)
      klass.class_exec do
        alias_method :state_before_explanation=,  :state=
        alias_method :advance_before_explanation, :advance

        remove_method :state=, :advance
      end
    end

    # Like #advance, but also pretty-print the token and its position
    # in the stream to `stdout`.
    def advance
      type, (val, range) = advance_before_explanation

      more = "(in-kwarg)" if @context.in_kwarg

      puts decorate(range,
                    Color.green("#{type} #{val.inspect}"),
                    "#{state.to_s.ljust(12)} #{@cond} #{@cmdarg} #{more}")

      [ type, [val, range] ]
    end

    def state=(new_state)
      puts "  #{Color.yellow(">>> STATE SET <<<", bold: true)} " +
           "#{new_state.to_s.ljust(12)} #{@cond} #{@cmdarg}".rjust(66)

      self.state_before_explanation = new_state
    end

    private

    def decorate(range, token, info)
      from, to = range.begin.column, range.end.column

      line = range.source_line + '   '
      line[from...to] = Color.underline(line[from...to])

      tail_len   = to - from - 1
      tail       = '~' * (tail_len >= 0 ? tail_len : 0)
      decoration =  "#{" " * from}#{Color.red("^#{tail}", bold: true)} #{token} ".
                        ljust(68) + info

      [ line, decoration ]
    end

  end

end
