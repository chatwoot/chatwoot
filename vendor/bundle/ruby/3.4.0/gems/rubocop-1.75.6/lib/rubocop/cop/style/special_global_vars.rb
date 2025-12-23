# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Looks for uses of Perl-style global variables.
      # Correcting to global variables in the 'English' library
      # will add a require statement to the top of the file if
      # enabled by RequireEnglish config.
      #
      # @safety
      #   Autocorrection is marked as unsafe because if `RequireEnglish` is not
      #   true, replacing perl-style variables with english variables will break.
      #
      # @example EnforcedStyle: use_english_names (default)
      #   # good
      #   require 'English' # or this could be in another file.
      #
      #   puts $LOAD_PATH
      #   puts $LOADED_FEATURES
      #   puts $PROGRAM_NAME
      #   puts $ERROR_INFO
      #   puts $ERROR_POSITION
      #   puts $FIELD_SEPARATOR # or $FS
      #   puts $OUTPUT_FIELD_SEPARATOR # or $OFS
      #   puts $INPUT_RECORD_SEPARATOR # or $RS
      #   puts $OUTPUT_RECORD_SEPARATOR # or $ORS
      #   puts $INPUT_LINE_NUMBER # or $NR
      #   puts $LAST_READ_LINE
      #   puts $DEFAULT_OUTPUT
      #   puts $DEFAULT_INPUT
      #   puts $PROCESS_ID # or $PID
      #   puts $CHILD_STATUS
      #   puts $LAST_MATCH_INFO
      #   puts $IGNORECASE
      #   puts $ARGV # or ARGV
      #
      # @example EnforcedStyle: use_perl_names
      #   # good
      #   puts $:
      #   puts $"
      #   puts $0
      #   puts $!
      #   puts $@
      #   puts $;
      #   puts $,
      #   puts $/
      #   puts $\
      #   puts $.
      #   puts $_
      #   puts $>
      #   puts $<
      #   puts $$
      #   puts $?
      #   puts $~
      #   puts $=
      #   puts $*
      #
      # @example EnforcedStyle: use_builtin_english_names
      #
      #   # good
      #   # Like `use_perl_names` but allows builtin global vars.
      #   puts $LOAD_PATH
      #   puts $LOADED_FEATURES
      #   puts $PROGRAM_NAME
      #   puts ARGV
      #   puts $:
      #   puts $"
      #   puts $0
      #   puts $!
      #   puts $@
      #   puts $;
      #   puts $,
      #   puts $/
      #   puts $\
      #   puts $.
      #   puts $_
      #   puts $>
      #   puts $<
      #   puts $$
      #   puts $?
      #   puts $~
      #   puts $=
      #   puts $*
      #
      class SpecialGlobalVars < Base
        include ConfigurableEnforcedStyle
        include RangeHelp
        include RequireLibrary
        extend AutoCorrector

        MSG_BOTH = 'Prefer `%<prefer>s` from the stdlib \'English\' ' \
                   'module (don\'t forget to require it) or `%<regular>s` over ' \
                   '`%<global>s`.'
        MSG_ENGLISH = 'Prefer `%<prefer>s` from the stdlib \'English\' ' \
                      'module (don\'t forget to require it) over `%<global>s`.'
        MSG_REGULAR = 'Prefer `%<prefer>s` over `%<global>s`.'

        ENGLISH_VARS = { # rubocop:disable Style/MutableConstant
          :$: => [:$LOAD_PATH],
          :$" => [:$LOADED_FEATURES],
          :$0 => [:$PROGRAM_NAME],
          :$! => [:$ERROR_INFO],
          :$@ => [:$ERROR_POSITION],
          :$; => %i[$FIELD_SEPARATOR $FS],
          :$, => %i[$OUTPUT_FIELD_SEPARATOR $OFS],
          :$/ => %i[$INPUT_RECORD_SEPARATOR $RS],
          :$\ => %i[$OUTPUT_RECORD_SEPARATOR $ORS],
          :$. => %i[$INPUT_LINE_NUMBER $NR],
          :$_ => [:$LAST_READ_LINE],
          :$> => [:$DEFAULT_OUTPUT],
          :$< => [:$DEFAULT_INPUT],
          :$$ => %i[$PROCESS_ID $PID],
          :$? => [:$CHILD_STATUS],
          :$~ => [:$LAST_MATCH_INFO],
          :$= => [:$IGNORECASE],
          :$* => %i[$ARGV ARGV]
        }

        # Anything *not* in this set is provided by the English library.
        NON_ENGLISH_VARS = Set.new(%i[$LOAD_PATH $LOADED_FEATURES $PROGRAM_NAME ARGV]).freeze

        PERL_VARS = ENGLISH_VARS.flat_map { |k, vs| vs.map { |v| [v, [k]] } }.to_h

        ENGLISH_VARS.merge!(ENGLISH_VARS.flat_map { |_, vs| vs.map { |v| [v, [v]] } }.to_h)
        PERL_VARS.merge!(PERL_VARS.flat_map { |_, vs| vs.map { |v| [v, [v]] } }.to_h)
        BUILTIN_VARS = PERL_VARS.merge(
          NON_ENGLISH_VARS
            .select { |v| v.to_s.start_with?('$') }
            .flat_map { |v| [[v, [v]], PERL_VARS[v].flat_map { |a| [a, [v]] }] }
            .to_h
        )

        ENGLISH_VARS.each_value(&:freeze).freeze
        PERL_VARS.each_value(&:freeze).freeze
        BUILTIN_VARS.each_value(&:freeze).freeze

        STYLE_VARS_MAP = {
          use_english_names: ENGLISH_VARS,
          use_perl_names: PERL_VARS,
          use_builtin_english_names: BUILTIN_VARS
        }.freeze

        LIBRARY_NAME = 'English'

        def on_new_investigation
          super
          @required_english = false
        end

        def on_gvar(node)
          global_var = node.name

          return unless (preferred = preferred_names(global_var))

          if preferred.include?(global_var)
            correct_style_detected
          else
            style_detected(matching_styles(global_var))

            add_offense(node, message: message(global_var)) do |corrector|
              autocorrect(corrector, node, global_var)
            end
          end
        end

        def message(global_var)
          if style == :use_english_names
            format_english_message(global_var)
          else
            format(MSG_REGULAR, prefer: preferred_names(global_var).first, global: global_var)
          end
        end

        def autocorrect(corrector, node, global_var)
          node = node.parent while node.parent&.begin_type? && node.parent.children.one?

          if should_require_english?(global_var)
            ensure_required(corrector, node, LIBRARY_NAME)

            @required_english = true
          end

          corrector.replace(node, replacement(node, global_var))
        end

        private

        def format_english_message(global_var)
          regular, english = ENGLISH_VARS[global_var].partition do |var|
            NON_ENGLISH_VARS.include? var
          end

          format_message(english, regular, global_var)
        end

        def format_message(english, regular, global)
          if regular.empty?
            format(MSG_ENGLISH, prefer: format_list(english), global: global)
          elsif english.empty?
            format(MSG_REGULAR, prefer: format_list(regular), global: global)
          else
            format(MSG_BOTH,
                   prefer: format_list(english),
                   regular: format_list(regular),
                   global: global)
          end
        end

        # For now, we assume that lists are 2 items or less. Easy grammar!
        def format_list(items)
          items.join('` or `')
        end

        def replacement(node, global_var)
          parent_type = node.parent&.type
          preferred_name = preferred_names(global_var).first

          return preferred_name.to_s unless %i[dstr xstr regexp].include?(parent_type)

          return english_name_replacement(preferred_name, node) if style == :use_english_names

          "##{preferred_name}"
        end

        def preferred_names(global)
          vars = STYLE_VARS_MAP.fetch(style) do
            raise ArgumentError, "Invalid style: #{style.inspect}"
          end

          vars[global]
        end

        def matching_styles(global)
          STYLE_VARS_MAP.filter_map do |style, vars|
            style if vars.values.flatten(1).include? global
          end
        end

        def english_name_replacement(preferred_name, node)
          return "\#{#{preferred_name}}" if node.begin_type?

          "{#{preferred_name}}"
        end

        def add_require_english?
          cop_config['RequireEnglish']
        end

        def should_require_english?(global_var)
          style == :use_english_names &&
            add_require_english? &&
            !@required_english &&
            !NON_ENGLISH_VARS.include?(preferred_names(global_var).first)
        end
      end
    end
  end
end
