# -*- encoding: utf-8 -*-
# stub: rubocop-factory_bot 2.27.1 ruby lib

Gem::Specification.new do |s|
  s.name = "rubocop-factory_bot".freeze
  s.version = "2.27.1".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "changelog_uri" => "https://github.com/rubocop/rubocop-factory_bot/blob/master/CHANGELOG.md", "default_lint_roller_plugin" => "RuboCop::FactoryBot::Plugin", "documentation_uri" => "https://docs.rubocop.org/rubocop-factory_bot/", "rubygems_mfa_required" => "true" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["John Backus".freeze, "Ian MacLeod".freeze, "Phil Pirozhkov".freeze, "Maxim Krizhanovsky".freeze, "Andrew Bromwich".freeze]
  s.date = "2025-03-13"
  s.description = "Code style checking for factory_bot files.\nA plugin for the RuboCop code style enforcing & linting tool.\n".freeze
  s.extra_rdoc_files = ["MIT-LICENSE.md".freeze, "README.md".freeze]
  s.files = ["MIT-LICENSE.md".freeze, "README.md".freeze]
  s.homepage = "https://github.com/rubocop/rubocop-factory_bot".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.7.0".freeze)
  s.rubygems_version = "3.6.2".freeze
  s.summary = "Code style checking for factory_bot files".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<lint_roller>.freeze, ["~> 1.1".freeze])
  s.add_runtime_dependency(%q<rubocop>.freeze, ["~> 1.72".freeze, ">= 1.72.1".freeze])
end
