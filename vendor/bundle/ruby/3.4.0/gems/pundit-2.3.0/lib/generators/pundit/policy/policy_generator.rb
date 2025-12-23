# frozen_string_literal: true

module Pundit
  module Generators
    class PolicyGenerator < ::Rails::Generators::NamedBase
      source_root File.expand_path("templates", __dir__)

      def create_policy
        template "policy.rb", File.join("app/policies", class_path, "#{file_name}_policy.rb")
      end

      hook_for :test_framework
    end
  end
end
