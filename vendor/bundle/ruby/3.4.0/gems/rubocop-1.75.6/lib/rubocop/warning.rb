# frozen_string_literal: true

module RuboCop
  # A Warning exception is different from an Offense with severity 'warning'
  # When a Warning is raised, this means that RuboCop was unable to perform a
  # requested operation (such as inspecting or correcting a source file) due to
  # user error
  # For example, a configuration value in .rubocop.yml might be malformed
  class Warning < StandardError
  end
end
