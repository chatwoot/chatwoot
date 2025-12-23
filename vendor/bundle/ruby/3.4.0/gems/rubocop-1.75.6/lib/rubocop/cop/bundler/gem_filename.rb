# frozen_string_literal: true

module RuboCop
  module Cop
    module Bundler
      # Verifies that a project contains Gemfile or gems.rb file and correct
      # associated lock file based on the configuration.
      #
      # @example EnforcedStyle: Gemfile (default)
      #   # bad
      #   Project contains gems.rb and gems.locked files
      #
      #   # bad
      #   Project contains Gemfile and gems.locked file
      #
      #   # good
      #   Project contains Gemfile and Gemfile.lock
      #
      # @example EnforcedStyle: gems.rb
      #   # bad
      #   Project contains Gemfile and Gemfile.lock files
      #
      #   # bad
      #   Project contains gems.rb and Gemfile.lock file
      #
      #   # good
      #   Project contains gems.rb and gems.locked files
      class GemFilename < Base
        include ConfigurableEnforcedStyle

        MSG_GEMFILE_REQUIRED = '`gems.rb` file was found but `Gemfile` is required ' \
                               '(file path: %<file_path>s).'
        MSG_GEMS_RB_REQUIRED = '`Gemfile` was found but `gems.rb` file is required ' \
                               '(file path: %<file_path>s).'
        MSG_GEMFILE_MISMATCHED = 'Expected a `Gemfile.lock` with `Gemfile` but found ' \
                                 '`gems.locked` file (file path: %<file_path>s).'
        MSG_GEMS_RB_MISMATCHED = 'Expected a `gems.locked` file with `gems.rb` but found ' \
                                 '`Gemfile.lock` (file path: %<file_path>s).'
        GEMFILE_FILES = %w[Gemfile Gemfile.lock].freeze
        GEMS_RB_FILES = %w[gems.rb gems.locked].freeze

        def on_new_investigation
          file_path = processed_source.file_path
          basename = File.basename(file_path)
          return if expected_gemfile?(basename)

          register_offense(file_path, basename)
        end

        private

        def register_offense(file_path, basename)
          register_gemfile_offense(file_path, basename) if gemfile_offense?(basename)
          register_gems_rb_offense(file_path, basename) if gems_rb_offense?(basename)
        end

        def register_gemfile_offense(file_path, basename)
          message = case basename
                    when 'gems.rb'
                      MSG_GEMFILE_REQUIRED
                    when 'gems.locked'
                      MSG_GEMFILE_MISMATCHED
                    end

          add_global_offense(format(message, file_path: file_path))
        end

        def register_gems_rb_offense(file_path, basename)
          message = case basename
                    when 'Gemfile'
                      MSG_GEMS_RB_REQUIRED
                    when 'Gemfile.lock'
                      MSG_GEMS_RB_MISMATCHED
                    end

          add_global_offense(format(message, file_path: file_path))
        end

        def gemfile_offense?(basename)
          gemfile_required? && GEMS_RB_FILES.include?(basename)
        end

        def gems_rb_offense?(basename)
          gems_rb_required? && GEMFILE_FILES.include?(basename)
        end

        def expected_gemfile?(basename)
          (gemfile_required? && GEMFILE_FILES.include?(basename)) ||
            (gems_rb_required? && GEMS_RB_FILES.include?(basename))
        end

        def gemfile_required?
          style == :Gemfile
        end

        def gems_rb_required?
          style == :'gems.rb'
        end
      end
    end
  end
end
