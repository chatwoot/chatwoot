# frozen_string_literal: true

require "ripper"

module TestProf
  module RSpecStamp
    # Parse examples headers
    module Parser
      # Contains the result of parsing
      class Result
        attr_accessor :fname, :desc, :desc_const
        attr_reader :tags, :htags

        def add_tag(v)
          @tags ||= []
          @tags << v
        end

        def add_htag(k, v)
          @htags ||= []
          @htags << [k, v]
        end

        def remove_tag(tag)
          @tags&.delete(tag)
          @htags&.delete_if { |(k, _v)| k == tag }
        end
      end

      class << self
        def parse(code)
          sexp = Ripper.sexp(code)
          return unless sexp

          # sexp has the following format:
          # [:program,
          #   [
          #     [
          #       :command,
          #       [:@ident, "it", [1, 0]],
          #       [:args_add_block, [ ... ]]
          #     ]
          #   ]
          # ]
          #
          # or
          #
          # [:program,
          #   [
          #     [
          #       :vcall,
          #       [:@ident, "it", [1, 0]]
          #     ]
          #   ]
          # ]
          res = Result.new

          fcall = sexp[1][0][1]
          args_block = sexp[1][0][2]

          if fcall.first == :fcall
            fcall = fcall[1]
          elsif fcall.first == :var_ref
            res.fname = [parse_const(fcall), sexp[1][0][3][1]].join(".")
            args_block = sexp[1][0][4]
          end

          res.fname ||= fcall[1]

          return res if args_block.nil?

          args_block = args_block[1] if args_block.first == :arg_paren

          args = args_block[1]

          if args.first.first == :string_literal
            res.desc = parse_literal(args.shift)
          elsif args.first.first == :var_ref || args.first.first == :const_path_ref
            res.desc_const = parse_const(args.shift)
          end

          parse_arg(res, args.shift) until args.empty?

          res
        end
        # rubocop: enable Metrics/CyclomaticComplexity
        # rubocop: enable Metrics/PerceivedComplexity

        private

        def parse_arg(res, arg)
          if arg.first == :symbol_literal
            res.add_tag parse_literal(arg)
          elsif arg.first == :bare_assoc_hash
            parse_hash(res, arg[1])
          end
        end

        def parse_hash(res, hash_arg)
          hash_arg.each do |(_, label, val)|
            res.add_htag label[1][0..-2].to_sym, parse_value(val)
          end
        end

        # Expr of the form:
        #  bool - [:var_ref, [:@kw, "true", [1, 24]]]
        #  string - [:string_literal, [:string_content, [...]]]
        #  int - [:@int, "3", [1, 52]]]]
        def parse_value(expr)
          case expr.first
          when :var_ref
            expr[1][1] == "true"
          when :@int
            expr[1].to_i
          when :@float
            expr[1].to_f
          else
            parse_literal(expr)
          end
        end

        # Expr of the form:
        #  [:string_literal, [:string_content, [:@tstring_content, "is", [1, 4]]]]
        def parse_literal(expr)
          val = expr[1][1][1]
          val = val.to_sym if expr[0] == :symbol_literal ||
            expr[0] == :assoc_new
          val
        end

        # Expr of the form:
        #  [:var_ref, [:@const, "User", [1, 9]]]
        #
        #  or
        #
        #  [:const_path_ref, [:const_path_ref, [:var_ref,
        #    [:@const, "User", [1, 17]]],
        #    [:@const, "Guest", [1, 23]]],
        #    [:@const, "Collection", [1, 30]]
        def parse_const(expr)
          if expr.first == :var_ref
            expr[1][1]
          elsif expr.first == :@const
            expr[1]
          elsif expr.first == :const_path_ref
            expr[1..-1].map(&method(:parse_const)).join("::")
          end
        end
      end
    end
  end
end
