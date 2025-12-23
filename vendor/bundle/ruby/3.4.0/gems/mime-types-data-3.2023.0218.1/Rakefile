# frozen_string_literal: true

require "rubygems"
require "hoe"
require "rake/clean"

Hoe.plugin :doofus
Hoe.plugin :gemspec2
Hoe.plugin :git
Hoe.plugin :travis
Hoe.plugin :email unless ENV["CI"] || ENV["TRAVIS"]

Hoe.spec "mime-types-data" do
  developer("Austin Ziegler", "halostatue@gmail.com")

  require_ruby_version ">= 2.0"

  self.history_file = "History.md"
  self.readme_file = "README.md"

  license "MIT"

  extra_dev_deps << ["nokogiri", "~> 1.6"]
  extra_dev_deps << ["hoe-doofus", "~> 1.0"]
  extra_dev_deps << ["hoe-gemspec2", "~> 1.1"]
  extra_dev_deps << ["hoe-git2", "~> 1.7"]
  extra_dev_deps << ["hoe-rubygems", "~> 1.0"]
  extra_dev_deps << ["rake", ">= 10.0", "< 14"]
  extra_dev_deps << ["mime-types", ">= 3.4.0", "< 4"]
  extra_dev_deps << ["standardrb", "~> 1.0"]
  extra_dev_deps << ["psych", "~> 3.0"]
end

$LOAD_PATH.unshift "lib"
$LOAD_PATH.unshift "support"

def new_version
  version =
    IO.read("lib/mime/types/data.rb").scan(/VERSION = ['"](\d\.\d{4}\.\d{4})['"]/).flatten.first

  major = Gem::Version.new(version).canonical_segments.first
  minor = Date.today.strftime("%Y.%m%d")

  "#{major}.#{minor}"
end

def release_header
  "#{new_version} / #{Date.today.strftime("%Y-%m-%d")}"
end

namespace :mime do
  desc "Download the current MIME type registrations from IANA."
  task :iana, [:destination] do |_, args|
    require "iana_registry"
    IANARegistry.download(to: args.destination)
  end

  desc "Download the current MIME type configuration from Apache."
  task :apache, [:destination] do |_, args|
    require "apache_mime_types"
    ApacheMIMETypes.download(to: args.destination)
  end
end

namespace :release do
  task __pull: %w[mime:apache mime:iana convert]
  task __prepare: %w[update:version update:history git:manifest]
  task :__commit do
    history = IO.read("History.md")
    message = history.scan(%r{## (#{release_header}.+?)## \d\.\d{4}\.\d{4} /}m).flatten.first

    IO.popen("git commit -a -F -", "w") { |commit|
      commit.puts message
    }
  end

  desc "Prepare a new automatic release"
  task automatic: :__pull do
    if system("git diff --quiet --exit-code") == false
      Rake::Task["release:__prepare"].invoke
      Rake::Task["gemspec"].invoke
      Rake::Task["release:__commit"].invoke
    else
      warn "No changes detected."
    end
  end
end

namespace :convert do
  namespace :yaml do
    desc "Convert from YAML to JSON"
    task :json, [:source, :destination, :multiple_files] => :support do |_, args|
      require "convert"
      Convert.from_yaml_to_json(args)
    end

    desc "Convert from YAML to Columnar"
    task :columnar, [:source, :destination] => :support do |_, args|
      require "convert/columnar"
      Convert::Columnar.from_yaml_to_columnar(args)
    end

    desc "Convert from YAML to mini_mime db format"
    task :mini_mime, [:source, :destination] => :support do |_, args|
      require "convert/mini_mime_db"
      Convert::MiniMimeDb.from_yaml_to_mini_mime(args)
    end
  end

  namespace :json do
    desc "Convert from JSON to YAML"
    task :yaml, [:source, :destination, :multiple_files] => :support do |_, args|
      require "convert"
      Convert.from_json_to_yaml(args)
    end
  end
end

namespace :update do
  desc "Update the release version"
  task :version do
    file = IO.read("lib/mime/types/data.rb")
    updated = file.sub(/VERSION = ['"][.0-9]+['"]/, %(VERSION = "#{new_version}"))

    IO.write("lib/mime/types/data.rb", updated)
  end

  desc "Update the history file with automatic release notes"
  task :history do
    history = IO.read("History.md")

    if !/^## #{release_header}$/.match?(history)
      note = <<-NOTE
<!-- automatic-release -->

## #{release_header}

- Updated the Apache and IANA media registry entries as of release date.
      NOTE

      updated = history.sub(/<!-- automatic-release -->\n/, note)

      IO.write("History.md", updated)
    end
  end
end

desc "Default conversion from YAML to JSON and Columnar"
task convert: ["convert:yaml:json", "convert:yaml:columnar", "convert:yaml:mini_mime"]

Rake::Task["gem"].prerequisites.unshift("convert")
Rake::Task["gem"].prerequisites.unshift("git:manifest")
Rake::Task["gem"].prerequisites.unshift("gemspec")

# vim: syntax=ruby
