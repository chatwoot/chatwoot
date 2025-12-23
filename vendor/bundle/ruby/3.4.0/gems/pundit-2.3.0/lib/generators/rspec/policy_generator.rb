# frozen_string_literal: true

module Rspec
  module Generators
    class PolicyGenerator < ::Rails::Generators::NamedBase
      source_root File.expand_path("templates", __dir__)

      def create_policy_spec
        template "policy_spec.rb", File.join("spec/policies", class_path, "#{file_name}_policy_spec.rb")
      end
    end
  end
end
