# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Looks for uses of global variables.
      # It does not report offenses for built-in global variables.
      # Built-in global variables are allowed by default. Additionally
      # users can allow additional variables via the AllowedVariables option.
      #
      # Note that backreferences like $1, $2, etc are not global variables.
      #
      # @example
      #   # bad
      #   $foo = 2
      #   bar = $foo + 5
      #
      #   # good
      #   FOO = 2
      #   foo = 2
      #   $stdin.read
      class GlobalVars < Base
        MSG = 'Do not introduce global variables.'

        # built-in global variables and their English aliases
        # https://www.zenspider.com/ruby/quickref.html
        BUILT_IN_VARS = %w[
          $: $LOAD_PATH
          $" $LOADED_FEATURES
          $0 $PROGRAM_NAME
          $! $ERROR_INFO
          $@ $ERROR_POSITION
          $; $FS $FIELD_SEPARATOR
          $, $OFS $OUTPUT_FIELD_SEPARATOR
          $/ $RS $INPUT_RECORD_SEPARATOR
          $\\ $ORS $OUTPUT_RECORD_SEPARATOR
          $. $NR $INPUT_LINE_NUMBER
          $_ $LAST_READ_LINE
          $> $DEFAULT_OUTPUT
          $< $DEFAULT_INPUT
          $$ $PID $PROCESS_ID
          $? $CHILD_STATUS
          $~ $LAST_MATCH_INFO
          $= $IGNORECASE
          $* $ARGV
          $& $MATCH
          $` $PREMATCH
          $' $POSTMATCH
          $+ $LAST_PAREN_MATCH
          $stdin $stdout $stderr
          $DEBUG $FILENAME $VERBOSE $SAFE
          $-0 $-a $-d $-F $-i $-I $-l $-p $-v $-w
          $CLASSPATH $JRUBY_VERSION $JRUBY_REVISION $ENV_JAVA
        ].map(&:to_sym)

        def user_vars
          cop_config['AllowedVariables'].map(&:to_sym)
        end

        def allowed_var?(global_var)
          BUILT_IN_VARS.include?(global_var) || user_vars.include?(global_var)
        end

        def on_gvar(node)
          check(node)
        end

        def on_gvasgn(node)
          check(node)
        end

        def check(node)
          add_offense(node.loc.name) unless allowed_var?(node.name)
        end
      end
    end
  end
end
