# frozen_string_literal: true

module RuboCop
  module AST
    class NodePattern
      # Functionality to turn `match_code` into methods/lambda
      module MethodDefiner
        def def_node_matcher(base, method_name, **defaults)
          def_helper(base, method_name, **defaults) do |name|
            params = emit_params('param0 = self')
            <<~RUBY
              def #{name}(#{params})
                #{VAR} = param0
                #{compile_init}
                #{emit_method_code}
              end
            RUBY
          end
        end

        def def_node_search(base, method_name, **defaults)
          def_helper(base, method_name, **defaults) do |name|
            emit_node_search(name)
          end
        end

        def compile_as_lambda
          <<~RUBY
            ->(#{emit_params('param0')}, block: nil) do
              #{VAR} = param0
              #{compile_init}
              #{emit_lambda_code}
            end
          RUBY
        end

        def as_lambda
          eval(compile_as_lambda) # rubocop:disable Security/Eval
        end

        private

        # This method minimizes the closure for our method
        def wrapping_block(method_name, **defaults)
          proc do |*args, **values|
            send method_name, *args, **defaults, **values
          end
        end

        def def_helper(base, method_name, **defaults)
          location = caller_locations(3, 1).first
          unless defaults.empty?
            call = :"without_defaults_#{method_name}"
            base.send :define_method, method_name, &wrapping_block(call, **defaults)
            method_name = call
          end
          src = yield method_name
          base.class_eval(src, location.path, location.lineno)

          method_name
        end

        def emit_node_search(method_name)
          if method_name.to_s.end_with?('?')
            on_match = 'return true'
          else
            args = emit_params(":#{method_name}", 'param0', forwarding: true)
            prelude = "return enum_for(#{args}) unless block_given?\n"
            on_match = emit_yield_capture(VAR)
          end
          emit_node_search_body(method_name, prelude: prelude, on_match: on_match)
        end

        def emit_node_search_body(method_name, prelude:, on_match:)
          <<~RUBY
            def #{method_name}(#{emit_params('param0')})
              #{compile_init}
              #{prelude}
              param0.each_node do |#{VAR}|
                if #{match_code}
                  #{on_match}
                end
              end
              nil
            end
          RUBY
        end

        def emit_yield_capture(when_no_capture = '', yield_with: 'yield')
          yield_val = if captures.zero?
                        when_no_capture
                      elsif captures == 1
                        'captures[0]' # Circumvent https://github.com/jruby/jruby/issues/5710
                      else
                        '*captures'
                      end
          "#{yield_with}(#{yield_val})"
        end

        def emit_retval
          if captures.zero?
            'true'
          elsif captures == 1
            'captures[0]'
          else
            'captures'
          end
        end

        def emit_param_list
          (1..positional_parameters).map { |n| "param#{n}" }.join(',')
        end

        def emit_keyword_list(forwarding: false)
          pattern = "%<keyword>s: #{'%<keyword>s' if forwarding}"
          named_parameters.map { |k| format(pattern, keyword: k) }.join(',')
        end

        def emit_params(*first, forwarding: false)
          params = emit_param_list
          keywords = emit_keyword_list(forwarding: forwarding)
          [*first, params, keywords].reject(&:empty?).join(',')
        end

        def emit_method_code
          <<~RUBY
            return unless #{match_code}
            block_given? ? #{emit_yield_capture} : (return #{emit_retval})
          RUBY
        end

        def emit_lambda_code
          <<~RUBY
            return unless #{match_code}
            block ? #{emit_yield_capture(yield_with: 'block.call')} : (return #{emit_retval})
          RUBY
        end

        def compile_init
          "captures = Array.new(#{captures})" if captures.positive?
        end
      end
    end
  end
end
