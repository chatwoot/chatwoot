# frozen_string_literal: true

require_relative "../ripper"

module Prism
  module Translation
    class Ripper
      # This class mirrors the ::Ripper::SexpBuilder subclass of ::Ripper that
      # returns the arrays of [type, *children].
      class SexpBuilder < Ripper
        # :stopdoc:

        attr_reader :error

        private

        def dedent_element(e, width)
          if (n = dedent_string(e[1], width)) > 0
            e[2][1] += n
          end
          e
        end

        def on_heredoc_dedent(val, width)
          sub = proc do |cont|
            cont.map! do |e|
              if Array === e
                case e[0]
                when :@tstring_content
                  e = dedent_element(e, width)
                when /_add\z/
                  e[1] = sub[e[1]]
                end
              elsif String === e
                dedent_string(e, width)
              end
              e
            end
          end
          sub[val]
          val
        end

        events = private_instance_methods(false).grep(/\Aon_/) {$'.to_sym}
        (PARSER_EVENTS - events).each do |event|
          module_eval(<<-End, __FILE__, __LINE__ + 1)
            def on_#{event}(*args)
              args.unshift :#{event}
            end
          End
        end

        SCANNER_EVENTS.each do |event|
          module_eval(<<-End, __FILE__, __LINE__ + 1)
            def on_#{event}(tok)
              [:@#{event}, tok, [lineno(), column()]]
            end
          End
        end

        def on_error(mesg)
          @error = mesg
        end
        remove_method :on_parse_error
        alias on_parse_error on_error
        alias compile_error on_error

        # :startdoc:
      end

      # This class mirrors the ::Ripper::SexpBuilderPP subclass of ::Ripper that
      # returns the same values as ::Ripper::SexpBuilder except with a couple of
      # niceties that flatten linked lists into arrays.
      class SexpBuilderPP < SexpBuilder
        # :stopdoc:

        private

        def on_heredoc_dedent(val, width)
          val.map! do |e|
            next e if Symbol === e and /_content\z/ =~ e
            if Array === e and e[0] == :@tstring_content
              e = dedent_element(e, width)
            elsif String === e
              dedent_string(e, width)
            end
            e
          end
          val
        end

        def _dispatch_event_new
          []
        end

        def _dispatch_event_push(list, item)
          list.push item
          list
        end

        def on_mlhs_paren(list)
          [:mlhs, *list]
        end

        def on_mlhs_add_star(list, star)
          list.push([:rest_param, star])
        end

        def on_mlhs_add_post(list, post)
          list.concat(post)
        end

        PARSER_EVENT_TABLE.each do |event, arity|
          if /_new\z/ =~ event and arity == 0
            alias_method "on_#{event}", :_dispatch_event_new
          elsif /_add\z/ =~ event
            alias_method "on_#{event}", :_dispatch_event_push
          end
        end

        # :startdoc:
      end
    end
  end
end
