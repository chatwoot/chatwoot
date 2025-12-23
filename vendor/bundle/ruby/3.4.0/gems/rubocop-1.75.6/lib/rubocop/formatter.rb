# frozen_string_literal: true

module RuboCop
  # The bootstrap module for formatter.
  module Formatter
    require_relative 'formatter/text_util'

    require_relative 'formatter/base_formatter'
    require_relative 'formatter/simple_text_formatter'

    # relies on simple text
    require_relative 'formatter/clang_style_formatter'
    require_relative 'formatter/disabled_config_formatter'
    require_relative 'formatter/emacs_style_formatter'
    require_relative 'formatter/file_list_formatter'
    require_relative 'formatter/fuubar_style_formatter'
    require_relative 'formatter/github_actions_formatter'
    require_relative 'formatter/html_formatter'
    require_relative 'formatter/json_formatter'
    require_relative 'formatter/junit_formatter'
    require_relative 'formatter/markdown_formatter'
    require_relative 'formatter/offense_count_formatter'
    require_relative 'formatter/pacman_formatter'
    require_relative 'formatter/progress_formatter'
    require_relative 'formatter/quiet_formatter'
    require_relative 'formatter/tap_formatter'
    require_relative 'formatter/worst_offenders_formatter'

    # relies on progress formatter
    require_relative 'formatter/auto_gen_config_formatter'

    require_relative 'formatter/formatter_set'
  end
end
